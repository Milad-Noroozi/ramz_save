import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_strings.dart';
import 'encryption_service.dart';

/// Keychain/Keystore-backed store for the vault's key material.
///
/// Nothing written here is a secret on its own: the salt is public by design,
/// and the DEK is stored wrapped under a key derived from the master password.
/// The master password itself is never written anywhere.
///
/// The one exception is the biometric copy of the DEK, which is stored in a
/// separate, biometry-gated entry — see [enableBiometricUnlock].
class SecureStorageService {
  static const _kSalt = 'kek_salt';
  static const _kIterations = 'kek_iterations';
  static const _kWrappedDek = 'wrapped_dek';
  static const _kVerifier = 'verifier';
  static const _kBiometricDek = 'biometric_dek';

  /// Constant sealed under the KEK at setup. Decrypting it is how a master
  /// password is checked without ever storing the password or its hash.
  static const _verifierPlaintext = 'ramz_save.v1';

  /// `resetOnError` defaults to **true** in this package: any keystore error
  /// wipes the store. For a password manager that means silently destroying the
  /// user's only copy of their vault key, so it is forced off everywhere here
  /// and errors are surfaced instead.
  static const _android = AndroidOptions(resetOnError: false);

  static const _ios = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  /// Biometry-gated variants. On Android the entry is bound to a hardware AES
  /// key that requires user authentication; on iOS the keychain item carries an
  /// access-control flag, so the OS shows the prompt during the read itself.
  ///
  /// [AccessControlFlag.biometryCurrentSet] rather than `biometryAny`: enrolling
  /// a new fingerprint or face invalidates the entry, so someone who adds their
  /// own biometric to an unlocked device still cannot open the vault.
  static const _androidBiometric = AndroidOptions.biometric(
    resetOnError: false,
    enforceBiometrics: true,
    biometricPromptTitle: AppStrings.appName,
    biometricPromptSubtitle: AppStrings.biometricReason,
    biometricPromptNegativeButton: AppStrings.cancel,
  );

  static const _iosBiometric = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    accessControlFlags: [AccessControlFlag.biometryCurrentSet],
  );

  final FlutterSecureStorage _storage;
  final FlutterSecureStorage _biometricStorage;

  SecureStorageService({
    FlutterSecureStorage? storage,
    FlutterSecureStorage? biometricStorage,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(aOptions: _android, iOptions: _ios),
       _biometricStorage =
           biometricStorage ??
           const FlutterSecureStorage(
             aOptions: _androidBiometric,
             iOptions: _iosBiometric,
           );

  /// True once a master password has been set up on this device.
  Future<bool> hasVault() async =>
      await _storage.read(key: _kWrappedDek) != null;

  /// Writes everything produced by first-time setup in one place, so a partial
  /// setup can't leave a wrapped DEK without the salt needed to unwrap it.
  Future<void> saveVaultKeys({
    required DerivedKey derived,
    required Uint8List dek,
  }) async {
    await _storage.write(key: _kSalt, value: base64Encode(derived.salt));
    await _storage.write(
      key: _kIterations,
      value: derived.iterations.toString(),
    );
    await _storage.write(
      key: _kVerifier,
      value: EncryptionService.encryptString(derived.key, _verifierPlaintext),
    );
    // Written last: [hasVault] keys off this entry, so it is the marker that
    // setup completed. If the process dies mid-write there is no half-set-up
    // vault, just an unused salt.
    await _storage.write(
      key: _kWrappedDek,
      value: EncryptionService.wrapDek(derived.key, dek),
    );
  }

  /// Re-derives the KEK for [password] and returns the unwrapped DEK, or
  /// `null` if the password is wrong.
  ///
  /// The verifier is checked first: it fails identically for a wrong password
  /// whether or not the DEK blob is also damaged.
  Future<Uint8List?> unlockDek(String password) async {
    final saltB64 = await _storage.read(key: _kSalt);
    final wrapped = await _storage.read(key: _kWrappedDek);
    final verifier = await _storage.read(key: _kVerifier);
    if (saltB64 == null || wrapped == null || verifier == null) return null;

    final rounds =
        int.tryParse(await _storage.read(key: _kIterations) ?? '') ??
        EncryptionService.iterations;

    final derived = await EncryptionService.deriveKeyAsync(
      password: password,
      salt: base64Decode(saltB64),
      rounds: rounds,
    );

    if (EncryptionService.decryptString(derived.key, verifier) !=
        _verifierPlaintext) {
      EncryptionService.wipe(derived.key);
      return null;
    }

    final dek = EncryptionService.unwrapDek(derived.key, wrapped);
    EncryptionService.wipe(derived.key);
    return dek;
  }

  /// Re-wraps the existing DEK under a new master password.
  ///
  /// Because only the wrapper changes, the vault contents are untouched — no
  /// bulk re-encryption, and no window where the box is half-converted.
  Future<void> rewrapDek({
    required Uint8List dek,
    required String newPassword,
  }) async {
    final derived = await EncryptionService.deriveKeyAsync(
      password: newPassword,
    );
    await saveVaultKeys(derived: derived, dek: dek);
    EncryptionService.wipe(derived.key);
  }

  /// Stores a copy of the DEK behind the OS's biometric gate.
  ///
  /// The protection is the keystore's own access control, not app-side
  /// encryption — a second layer would need a key we'd have nowhere to hide.
  /// Because this entry is independent of the KEK, changing the master password
  /// does not invalidate it.
  Future<void> enableBiometricUnlock(Uint8List dek) =>
      _biometricStorage.write(key: _kBiometricDek, value: base64Encode(dek));

  /// Removes the biometric copy. Failures are swallowed: a keystore that has
  /// already invalidated the entry (new fingerprint enrolled, biometrics
  /// removed) throws on delete, and the desired end state — no usable biometric
  /// key — is reached either way.
  Future<void> disableBiometricUnlock() async {
    try {
      await _biometricStorage.delete(key: _kBiometricDek);
    } catch (_) {
      // Already gone or unreadable; nothing left to remove.
    }
  }

  /// Whether a biometric copy exists. On iOS this reads only the item's
  /// presence, not its contents, so it does not raise a prompt.
  Future<bool> hasBiometricDek() async {
    try {
      return await _biometricStorage.containsKey(key: _kBiometricDek);
    } catch (_) {
      return false;
    }
  }

  /// Returns the DEK stored for biometric unlock.
  ///
  /// **The OS shows its biometric prompt during this call.** A `null` result
  /// covers both a cancelled prompt and an invalidated entry; callers should
  /// fall back to the master password rather than distinguishing them.
  Future<Uint8List?> readBiometricDek() async {
    try {
      final value = await _biometricStorage.read(key: _kBiometricDek);
      if (value == null) return null;
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  /// Erases all key material. Without the DEK the encrypted box is
  /// unrecoverable, which is what makes this a real reset.
  Future<void> wipe() async {
    await disableBiometricUnlock();
    await _storage.deleteAll();
  }
}
