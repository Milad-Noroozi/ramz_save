import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../config/app_strings.dart';
import '../models/user_model.dart';
import '../services/biometric_service.dart';
import '../services/encryption_service.dart';
import '../services/local_db_service.dart';
import '../services/secure_storage_service.dart';

/// Where the app is in the lock lifecycle.
enum AuthStatus {
  /// Before [AuthController.bootstrap] has finished — the splash screen.
  unknown,

  /// No master password on this device yet.
  needsSetup,

  /// Vault exists, key not in memory.
  locked,

  /// Key in memory, database open.
  unlocked,
}

/// Owns the master password lifecycle and, with it, the vault key.
///
/// This is the only object that holds the DEK in memory. It is released on
/// every lock — including auto-lock — and the encrypted box is closed with it,
/// so a locked app has no decrypted vault data anywhere in the process.
class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  final SecureStorageService _secureStorage;
  final LocalDbService _db;
  final BiometricService _biometrics;

  AuthController({
    SecureStorageService? secureStorage,
    LocalDbService? db,
    BiometricService? biometrics,
  }) : _secureStorage = secureStorage ?? SecureStorageService(),
       _db = db ?? LocalDbService(),
       _biometrics = biometrics ?? BiometricService();

  /// Shared with the vault controller, which reads through it once unlocked.
  LocalDbService get db => _db;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;
  bool get isUnlocked => _status == AuthStatus.unlocked;

  bool _busy = false;
  bool get isBusy => _busy;

  String? _error;
  String? get error => _error;

  UserModel? _user;
  UserModel? get user => _user;

  BiometricAvailability _biometricAvailability = BiometricAvailability.ready;
  BiometricAvailability get biometricAvailability => _biometricAvailability;

  bool _biometricEnabled = false;

  /// Whether the unlock screen should offer the biometric button: the user
  /// turned it on, a key copy exists, and the hardware is still usable.
  bool get canUseBiometric =>
      _biometricEnabled && _biometricAvailability.isReady;

  /// Held only while unlocked. Never persisted, never logged, never leaves this
  /// object — the database takes it once, at open.
  Uint8List? _dek;

  DateTime? _backgroundedAt;

  /// Set while the OS is showing its own prompt on top of us.
  ///
  /// The biometric sheet and the file picker both background the app, which
  /// would otherwise read as "user left" and auto-lock the vault the instant
  /// they appear — locking the app during the very prompt meant to unlock it.
  bool _systemPromptActive = false;

  /// Reads device state and decides the first screen. Safe to call once, at
  /// startup, before any UI depends on [status].
  Future<void> bootstrap() async {
    WidgetsBinding.instance.addObserver(this);
    await LocalDbService.init();

    _biometricAvailability = await _biometrics.availability();
    _biometricEnabled = await _secureStorage.hasBiometricDek();
    // A wrapped key in the keychain is not the same as a vault on disk: iOS
    // keeps the keychain when the app is deleted, so a reinstall can leave
    // key material pointing at a database that is gone. Both must exist
    // before the app presents a lock screen.
    final vaultExists = await _db.vaultExistsOnDisk;
    _status = await _secureStorage.hasVault() && vaultExists
        ? AuthStatus.locked
        : AuthStatus.needsSetup;

    notifyListeners();
  }

  /// First-time setup. Generates the DEK, wraps it under the new password, and
  /// leaves the app unlocked — the user should not have to log in immediately
  /// after choosing their password.
  Future<bool> createVault({
    required String name,
    required String password,
  }) async {
    return _guard(() async {
      final derived = await EncryptionService.deriveKeyAsync(password: password);
      final dek = EncryptionService.generateDek();

      await _secureStorage.saveVaultKeys(derived: derived, dek: dek);
      EncryptionService.wipe(derived.key);

      await _openWith(dek);
      await _saveUser(UserModel(name: name, createdAt: DateTime.now()));
      return true;
    });
  }

  /// Unlocks with the master password. `false` means the password was wrong.
  Future<bool> unlock(String password) async {
    return _guard(() async {
      final dek = await _secureStorage.unlockDek(password);
      if (dek == null) {
        _error = AppStrings.wrongMasterPassword;
        return false;
      }
      await _openWith(dek);
      return true;
    });
  }

  /// Unlocks via the keystore's biometric gate.
  ///
  /// The OS prompt happens inside [SecureStorageService.readBiometricDek] — no
  /// separate `local_auth` call, which would prompt twice and prove nothing.
  Future<bool> unlockWithBiometric() async {
    return _guard(() async {
      _systemPromptActive = true;
      try {
        final dek = await _secureStorage.readBiometricDek();
        if (dek == null) {
          // Cancelled, or the entry was invalidated by a biometric change.
          // Either way the master password still works, so say nothing loud.
          return false;
        }
        await _openWith(dek);
        return true;
      } finally {
        _systemPromptActive = false;
      }
    });
  }

  /// Drops the key and closes the database. Idempotent.
  Future<void> lock() async {
    if (_status == AuthStatus.needsSetup) return;

    await _db.close();
    final dek = _dek;
    if (dek != null) EncryptionService.wipe(dek);
    _dek = null;
    _user = null;
    _backgroundedAt = null;
    _status = AuthStatus.locked;
    notifyListeners();
  }

  /// Re-wraps the DEK under a new master password. Returns `false` when
  /// [current] is wrong.
  ///
  /// The vault itself is untouched: only the wrapper changes, so there is no
  /// window in which the database is half-converted.
  Future<bool> changeMasterPassword({
    required String current,
    required String next,
  }) async {
    return _guard(() async {
      final dek = _dek;
      if (dek == null) return false;

      // Verify the old password against the keystore rather than trusting that
      // the session is unlocked — an unlocked app left on a desk is exactly the
      // situation this check is for.
      final verified = await _secureStorage.unlockDek(current);
      if (verified == null) {
        _error = AppStrings.wrongMasterPassword;
        return false;
      }
      EncryptionService.wipe(verified);

      await _secureStorage.rewrapDek(dek: dek, newPassword: next);
      return true;
    });
  }

  /// Turns biometric unlock on or off.
  ///
  /// Enabling stores a second copy of the DEK behind the OS biometric gate; it
  /// requires an unlocked session, since there is no key to copy otherwise.
  Future<bool> setBiometricEnabled(bool enabled) async {
    return _guard(() async {
      if (!enabled) {
        await _secureStorage.disableBiometricUnlock();
        _biometricEnabled = false;
        await _saveUser(_user?.copyWith(useBiometric: false));
        return true;
      }

      final dek = _dek;
      if (dek == null) {
        _error = AppStrings.biometricEnableFirst;
        return false;
      }

      _biometricAvailability = await _biometrics.availability();
      if (!_biometricAvailability.isReady) {
        _error = _biometricAvailability.message;
        return false;
      }

      _systemPromptActive = true;
      try {
        await _secureStorage.enableBiometricUnlock(dek);
      } catch (_) {
        _error = AppStrings.biometricFailed;
        return false;
      } finally {
        _systemPromptActive = false;
      }

      _biometricEnabled = true;
      await _saveUser(_user?.copyWith(useBiometric: true));
      return true;
    });
  }

  /// Persists profile and preference edits.
  Future<void> updateUser(UserModel updated) async {
    await _saveUser(updated);
    notifyListeners();
  }

  /// Erases the key material and the database — the "forgot my master password"
  /// escape hatch. Everything stored is unrecoverable afterwards, by design.
  Future<void> resetEverything() async {
    await _db.destroy();
    await _secureStorage.wipe();
    final dek = _dek;
    if (dek != null) EncryptionService.wipe(dek);
    _dek = null;
    _user = null;
    _biometricEnabled = false;
    _status = AuthStatus.needsSetup;
    notifyListeners();
  }

  /// Suppresses auto-lock across a system prompt the app itself raised, such as
  /// the backup file picker. Without this, choosing a file would lock the vault
  /// out from under the screen that asked for it.
  Future<T> duringSystemPrompt<T>(Future<T> Function() action) async {
    _systemPromptActive = true;
    try {
      return await action();
    } finally {
      _systemPromptActive = false;
    }
  }

  // ── Auto-lock ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isUnlocked || _systemPromptActive) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundedAt = DateTime.now();

        // `immediately` cannot wait for the return trip: the app may be killed
        // while backgrounded, and the point of the setting is that the vault is
        // shut the moment it leaves the screen.
        if (_autoLock.duration == Duration.zero) unawaited(lock());

      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        final limit = _autoLock.duration;
        if (since == null || limit == null) return;
        if (DateTime.now().difference(since) >= limit) unawaited(lock());

      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // `inactive` fires for transient interruptions — the app switcher, a
        // notification shade — which are not a departure.
        break;
    }
  }

  AutoLockDuration get _autoLock =>
      _user?.autoLock ?? AutoLockDuration.fiveMinutes;

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Takes ownership of [dek]: opens the database and moves to unlocked.
  Future<void> _openWith(Uint8List dek) async {
    await _db.open(dek);
    _dek = dek;
    _user = _db.readUser();
    _status = AuthStatus.unlocked;
  }

  Future<void> _saveUser(UserModel? updated) async {
    if (updated == null || !_db.isOpen) return;
    _user = updated;
    await _db.saveUser(updated);
  }

  /// Runs [action] with the busy flag set and the previous error cleared,
  /// turning anything thrown into a message rather than an unhandled crash on
  /// a screen the user cannot leave.
  Future<bool> _guard(Future<bool> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } catch (_) {
      _error = AppStrings.storageError;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
