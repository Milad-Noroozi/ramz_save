import 'package:flutter/foundation.dart';

import '../config/app_strings.dart';
import '../models/user_model.dart';
import '../services/backup_service.dart';
import 'auth_controller.dart';
import 'vault_controller.dart';

/// The outcome of a backup export or import, ready to show in a snackbar.
class BackupOutcome {
  final bool succeeded;
  final String message;

  /// Where the file was written, for the "saved to…" line on mobile.
  final String? path;

  /// How many entries came back in, for the restore message.
  final int? importedCount;

  const BackupOutcome({
    required this.succeeded,
    required this.message,
    this.path,
    this.importedCount,
  });

  /// The user dismissed the file dialog. Not a failure worth a message.
  static const dismissed = BackupOutcome(succeeded: false, message: '');

  bool get isSilent => !succeeded && message.isEmpty;
}

/// Settings screen state: preferences, and backup export/import.
///
/// It leans on [AuthController] for anything touching key material — this class
/// never sees the DEK or the master password.
class SettingsController extends ChangeNotifier {
  final AuthController _auth;
  final VaultController _vaults;
  final BackupService _backup;

  SettingsController({
    required AuthController auth,
    required VaultController vaults,
    BackupService? backup,
  }) : _auth = auth,
       _vaults = vaults,
       _backup = backup ?? BackupService();

  bool _busy = false;
  bool get isBusy => _busy;

  UserModel? get user => _auth.user;

  bool get useBiometric => _auth.canUseBiometric;
  AutoLockDuration get autoLock =>
      _auth.user?.autoLock ?? AutoLockDuration.fiveMinutes;
  bool get checkBreachesOnline => _auth.user?.checkBreachesOnline ?? false;

  Future<void> setAutoLock(AutoLockDuration value) async {
    final current = _auth.user;
    if (current == null) return;
    await _auth.updateUser(current.copyWith(autoLock: value));
    notifyListeners();
  }

  /// Turning the online check on runs it immediately, so the health screen
  /// reflects the new setting without the user having to hunt for a refresh.
  Future<void> setCheckBreachesOnline(bool value) async {
    final current = _auth.user;
    if (current == null) return;
    await _auth.updateUser(current.copyWith(checkBreachesOnline: value));
    notifyListeners();
    if (value) await _vaults.refreshOnlineBreaches();
  }

  /// Encrypts the vault under [password] and writes it out.
  ///
  /// [password] is the *backup* password, not the master password: a file that
  /// leaves the device shouldn't inherit a password chosen for on-device
  /// unlocking, and this way the user can hand over a backup without handing
  /// over their master password.
  Future<BackupOutcome> exportBackup(String password) async {
    _setBusy(true);
    try {
      final now = DateTime.now();
      final content = await BackupService.encode(
        vaults: _vaults.all,
        password: password,
        createdAt: now,
        user: _auth.user,
      );

      // The save dialog backgrounds the app; without this the vault would
      // auto-lock the moment the picker appears.
      final path = await _auth.duringSystemPrompt(
        () => _backup.exportToFile(
          content: content,
          suggestedName: BackupService.suggestedFileName(now),
        ),
      );

      if (path == null) return BackupOutcome.dismissed;
      return BackupOutcome(
        succeeded: true,
        message: AppStrings.backupExported,
        path: path,
      );
    } catch (_) {
      return const BackupOutcome(
        succeeded: false,
        message: AppStrings.genericError,
      );
    } finally {
      _setBusy(false);
    }
  }

  /// Reads a backup file and merges its entries into the vault.
  ///
  /// Merge, not replace: entries are keyed by id, so restoring onto a populated
  /// vault updates what matches and adds what doesn't, instead of destroying
  /// anything the backup predates.
  Future<BackupOutcome> importBackup(String password) async {
    _setBusy(true);
    try {
      final content = await _auth.duringSystemPrompt(_backup.pickBackupFile);
      if (content == null) return BackupOutcome.dismissed;

      final result = await BackupService.decode(content, password);
      if (!result.isSuccess) {
        return BackupOutcome(
          succeeded: false,
          message: switch (result.error!) {
            BackupError.wrongPassword => AppStrings.backupWrongPassword,
            BackupError.invalidFile ||
            BackupError.unsupportedVersion ||
            BackupError.ioFailure => AppStrings.backupInvalidFile,
          },
        );
      }

      await _vaults.importAll(result.vaults);
      return BackupOutcome(
        succeeded: true,
        message: AppStrings.backupImported,
        importedCount: result.vaults.length,
      );
    } catch (_) {
      return const BackupOutcome(
        succeeded: false,
        message: AppStrings.genericError,
      );
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
