import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import '../models/user_model.dart';
import '../models/vault_model.dart';
import 'encryption_service.dart';

/// Why a backup file could not be opened. Kept separate from a thrown error so
/// the UI can tell "wrong password" from "not one of our files" — the two need
/// very different messages.
enum BackupError { invalidFile, wrongPassword, unsupportedVersion, ioFailure }

/// The result of reading a backup: either its contents or a reason.
class BackupContents {
  final List<VaultModel> vaults;
  final UserModel? user;
  final DateTime? createdAt;
  final BackupError? error;

  const BackupContents._({
    this.vaults = const [],
    this.user,
    this.createdAt,
    this.error,
  });

  const BackupContents.failure(BackupError error) : this._(error: error);

  bool get isSuccess => error == null;
}

/// Encrypted export and import of the whole vault.
///
/// The backup is sealed under its **own** password, not the master password.
/// That keeps a file that leaves the device from inheriting the strength of a
/// password chosen for on-device unlocking, and lets the user hand a backup to
/// someone without handing over their master password.
///
/// File layout — the envelope is plaintext JSON so a future version can read
/// the KDF parameters before it knows how to decrypt anything:
///
/// ```json
/// {
///   "format": "ramz_save.backup",
///   "version": 1,
///   "createdAt": "2026-08-09T…",
///   "kdf": { "algorithm": "PBKDF2-HMAC-SHA256", "iterations": 100000,
///            "salt": "<base64>" },
///   "payload": "<base64 AES-256-GCM of the entries JSON>"
/// }
/// ```
class BackupService {
  static const _format = 'ramz_save.backup';
  static const _version = 1;

  /// Extension chosen so the OS doesn't hand the file to a JSON viewer that
  /// would show the envelope and invite someone to "fix" it.
  static const fileExtension = 'ramzsave';

  /// Serialises and encrypts. Pure — takes no I/O, so it is directly testable.
  static Future<String> encode({
    required List<VaultModel> vaults,
    required String password,
    required DateTime createdAt,
    UserModel? user,
  }) async {
    final derived = await EncryptionService.deriveKeyAsync(password: password);

    final plaintext = jsonEncode({
      'vaults': vaults.map((v) => v.toJson()).toList(),
      'user': user?.toJson(),
    });

    final envelope = {
      'format': _format,
      'version': _version,
      'createdAt': createdAt.toIso8601String(),
      'kdf': {
        'algorithm': 'PBKDF2-HMAC-SHA256',
        'iterations': derived.iterations,
        'salt': base64Encode(derived.salt),
      },
      'payload': EncryptionService.encryptString(derived.key, plaintext),
    };

    EncryptionService.wipe(derived.key);
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Inverse of [encode]. Never throws — every failure becomes a
  /// [BackupContents.failure] so the caller has one path to handle.
  static Future<BackupContents> decode(String content, String password) async {
    final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return const BackupContents.failure(BackupError.invalidFile);
      }
      envelope = decoded;
    } catch (_) {
      return const BackupContents.failure(BackupError.invalidFile);
    }

    if (envelope['format'] != _format) {
      return const BackupContents.failure(BackupError.invalidFile);
    }
    if ((envelope['version'] as num?)?.toInt() != _version) {
      return const BackupContents.failure(BackupError.unsupportedVersion);
    }

    final kdf = envelope['kdf'];
    final payload = envelope['payload'];
    if (kdf is! Map || payload is! String) {
      return const BackupContents.failure(BackupError.invalidFile);
    }

    final Uint8List salt;
    try {
      salt = base64Decode(kdf['salt'] as String);
    } catch (_) {
      return const BackupContents.failure(BackupError.invalidFile);
    }

    final derived = await EncryptionService.deriveKeyAsync(
      password: password,
      salt: salt,
      rounds:
          (kdf['iterations'] as num?)?.toInt() ?? EncryptionService.iterations,
    );

    final plaintext = EncryptionService.decryptString(derived.key, payload);
    EncryptionService.wipe(derived.key);

    // A failed GCM tag is indistinguishable from a wrong key, which is exactly
    // what it usually means here.
    if (plaintext == null) {
      return const BackupContents.failure(BackupError.wrongPassword);
    }

    try {
      final body = jsonDecode(plaintext) as Map<String, dynamic>;
      final vaults = (body['vaults'] as List? ?? const [])
          .whereType<Map>()
          .map(VaultModel.fromJson)
          .toList();
      final userJson = body['user'];

      return BackupContents._(
        vaults: vaults,
        user: userJson is Map ? UserModel.fromJson(userJson) : null,
        createdAt: DateTime.tryParse(envelope['createdAt'] as String? ?? ''),
      );
    } catch (_) {
      // Decryption succeeded, so the password was right — the contents are the
      // problem.
      return const BackupContents.failure(BackupError.invalidFile);
    }
  }

  /// Writes a backup and returns the path it landed on, or `null` if the user
  /// dismissed the save dialog.
  ///
  /// Desktop gets a real save dialog. Android and iOS have no such dialog in
  /// `file_selector`, so the file goes to the app's documents directory and the
  /// path is returned for the UI to show — on iOS that folder is visible in the
  /// Files app, and on Android it is reachable over USB or a file manager.
  Future<String?> exportToFile({
    required String content,
    required String suggestedName,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$suggestedName');
      await file.writeAsString(content, flush: true);
      return file.path;
    }

    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [_typeGroup],
    );
    if (location == null) return null;

    await File(location.path).writeAsString(content, flush: true);
    return location.path;
  }

  /// Opens a file picker and returns the file's text, or `null` if dismissed.
  Future<String?> pickBackupFile() async {
    // Android's picker filters by MIME type and has no mapping for a custom
    // extension, so leaving the group off is what makes our own files
    // selectable there.
    final file = await openFile(
      acceptedTypeGroups: Platform.isAndroid ? const [] : const [_typeGroup],
    );
    if (file == null) return null;
    return file.readAsString();
  }

  static const _typeGroup = XTypeGroup(
    label: 'Ramz Save',
    extensions: [fileExtension],
    uniformTypeIdentifiers: ['public.data'],
  );

  /// A filename that sorts chronologically and never collides within a day.
  static String suggestedFileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'ramzsave-${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}.$fileExtension';
  }
}
