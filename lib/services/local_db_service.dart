import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/password_model.dart';
import '../models/user_model.dart';
import '../models/vault_model.dart';

/// The encrypted local database.
///
/// One AES-encrypted Hive box per concern, all opened with the same DEK. The
/// key never appears in this class beyond the [open] call — Hive holds the
/// cipher, and everything after that is ordinary map access.
///
/// Entries are stored as plain `Map`s rather than generated adapters: it keeps
/// the build codegen-free, and makes the backup format identical in shape to
/// what is on disk.
class LocalDbService {
  static const _vaultBox = 'vaults';
  static const _prefsBox = 'prefs';

  static const _kUser = 'user';
  static const _kGeneratorOptions = 'generator_options';

  Box<dynamic>? _vaults;
  Box<dynamic>? _prefs;

  /// True between a successful [open] and the next [close].
  bool get isOpen => _vaults?.isOpen ?? false;

  Box<dynamic> get _requireVaults {
    final box = _vaults;
    if (box == null || !box.isOpen) {
      throw StateError('Vault box accessed while locked');
    }
    return box;
  }

  Box<dynamic> get _requirePrefs {
    final box = _prefs;
    if (box == null || !box.isOpen) {
      throw StateError('Prefs box accessed while locked');
    }
    return box;
  }

  /// Registers Hive's storage directory. Safe to call more than once.
  static Future<void> init() => Hive.initFlutter();

  /// Opens the boxes under [dek].
  ///
  /// A wrong key surfaces here as a Hive read failure rather than as garbled
  /// entries, because the box's own checksum is verified on open.
  Future<void> open(Uint8List dek) async {
    if (isOpen) return;
    final cipher = HiveAesCipher(dek);
    _vaults = await Hive.openBox<dynamic>(_vaultBox, encryptionCipher: cipher);
    _prefs = await Hive.openBox<dynamic>(_prefsBox, encryptionCipher: cipher);
  }

  /// Closes the boxes, dropping the decrypted contents from memory. Called on
  /// every auto-lock, not just on exit.
  Future<void> close() async {
    await _vaults?.close();
    await _prefs?.close();
    _vaults = null;
    _prefs = null;
  }

  // ── Vaults ────────────────────────────────────────────────────────────────

  /// All entries, newest first.
  ///
  /// Rows that fail to parse are skipped rather than thrown on: one corrupt
  /// entry should not make the whole vault unreadable.
  List<VaultModel> readVaults() {
    final result = <VaultModel>[];
    for (final value in _requireVaults.values) {
      if (value is! Map) continue;
      try {
        result.add(VaultModel.fromJson(value));
      } catch (_) {
        continue;
      }
    }
    result.sort((a, b) {
      final at = a.updatedAt ?? a.createdAt;
      final bt = b.updatedAt ?? b.createdAt;
      return bt.compareTo(at);
    });
    return result;
  }

  VaultModel? readVault(String id) {
    final value = _requireVaults.get(id);
    if (value is! Map) return null;
    try {
      return VaultModel.fromJson(value);
    } catch (_) {
      return null;
    }
  }

  /// Inserts or replaces — the id is the box key, so saving an edited entry
  /// overwrites in place instead of leaving a duplicate.
  Future<void> saveVault(VaultModel vault) =>
      _requireVaults.put(vault.id, vault.toJson());

  Future<void> saveVaults(Iterable<VaultModel> vaults) => _requireVaults.putAll({
    for (final v in vaults) v.id: v.toJson(),
  });

  Future<void> deleteVault(String id) => _requireVaults.delete(id);

  Future<void> clearVaults() => _requireVaults.clear();

  int get vaultCount => _requireVaults.length;

  // ── Preferences ───────────────────────────────────────────────────────────

  UserModel? readUser() {
    final value = _requirePrefs.get(_kUser);
    if (value is! Map) return null;
    try {
      return UserModel.fromJson(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) =>
      _requirePrefs.put(_kUser, user.toJson());

  /// Falls back to the defaults when nothing has been saved yet, so the
  /// generator screen always has usable options.
  PasswordOptions readGeneratorOptions() {
    final value = _requirePrefs.get(_kGeneratorOptions);
    if (value is! Map) return const PasswordOptions();
    try {
      return PasswordOptions.fromJson(value);
    } catch (_) {
      return const PasswordOptions();
    }
  }

  Future<void> saveGeneratorOptions(PasswordOptions options) =>
      _requirePrefs.put(_kGeneratorOptions, options.toJson());

  /// Deletes the boxes from disk. Paired with wiping the key material — on its
  /// own it would leave an unreadable but present database.
  Future<void> destroy() async {
    await close();
    await Hive.deleteBoxFromDisk(_vaultBox);
    await Hive.deleteBoxFromDisk(_prefsBox);
  }
}
