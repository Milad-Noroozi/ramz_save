import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/app_helper.dart';
import '../../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

/// Export and restore.
///
/// The backup file carries its own password, deliberately separate from the
/// master password: a file that leaves the device shouldn't be openable with
/// the credential that unlocks the device, and a user should be able to hand
/// someone a backup without handing over the vault.
class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  final _exportForm = GlobalKey<FormState>();
  final _importForm = GlobalKey<FormState>();
  final _exportPassword = TextEditingController();
  final _exportConfirm = TextEditingController();
  final _importPassword = TextEditingController();

  @override
  void dispose() {
    _exportPassword.dispose();
    _exportConfirm.dispose();
    _importPassword.dispose();
    super.dispose();
  }

  void _report(BackupOutcome outcome) {
    // A dismissed file picker isn't a failure — the user simply changed their
    // mind, and a snackbar about it would be noise.
    if (outcome.isSilent) return;

    final count = outcome.importedCount;
    final message = count != null
        ? '${outcome.message} — ${AppHelper.number(count)} '
              '${AppStrings.importedCount}'
        : outcome.message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: outcome.succeeded ? null : AppColors.error,
      ),
    );
  }

  Future<void> _export() async {
    if (!_exportForm.currentState!.validate()) return;

    final outcome = await context.read<SettingsController>().exportBackup(
      _exportPassword.text,
    );
    if (!mounted) return;

    if (outcome.succeeded) {
      _exportPassword.clear();
      _exportConfirm.clear();
    }
    _report(outcome);
  }

  Future<void> _import() async {
    if (!_importForm.currentState!.validate()) return;

    final outcome = await context.read<SettingsController>().importBackup(
      _importPassword.text,
    );
    if (!mounted) return;

    if (outcome.succeeded) _importPassword.clear();
    _report(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<SettingsController, bool>((s) => s.isBusy);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.backupAndRestore)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _ExplainCard(),
            const SizedBox(height: 24),

            _Card(
              icon: Icons.upload_file_rounded,
              title: AppStrings.exportBackup,
              color: AppColors.green,
              child: Form(
                key: _exportForm,
                child: Column(
                  children: [
                    CustomTextField.password(
                      controller: _exportPassword,
                      label: AppStrings.backupPassword,
                      hint: AppStrings.backupPasswordHint,
                      textInputAction: TextInputAction.next,
                      validator: Validators.masterPassword,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField.password(
                      controller: _exportConfirm,
                      label: AppStrings.confirmMasterPassword,
                      hint: AppStrings.confirmMasterPasswordHint,
                      textInputAction: TextInputAction.done,
                      // Confirmed, because a typo here is only discovered on the
                      // day the backup is needed — and then it is unopenable.
                      validator: (v) =>
                          Validators.confirmPassword(v, _exportPassword.text),
                      onSubmitted: busy ? null : _export,
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      text: AppStrings.exportBackup,
                      icon: Icons.ios_share_rounded,
                      color: AppColors.green,
                      isLoading: busy,
                      onPressed: _export,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            _Card(
              icon: Icons.download_rounded,
              title: AppStrings.importBackup,
              color: AppColors.blue,
              child: Form(
                key: _importForm,
                child: Column(
                  children: [
                    CustomTextField.password(
                      controller: _importPassword,
                      label: AppStrings.backupPassword,
                      hint: AppStrings.backupPasswordHint,
                      textInputAction: TextInputAction.done,
                      // Only presence is checked: an old backup may predate the
                      // current length rule, and rejecting it here would lock
                      // the user out of their own file.
                      validator: Validators.required,
                      onSubmitted: busy ? null : _import,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.importMergeNote,
                      style: AppTextStyles.bodySmall.copyWith(height: 1.8),
                    ),
                    const SizedBox(height: 18),
                    CustomButton.outlined(
                      text: AppStrings.pickBackupFile,
                      icon: Icons.folder_open_rounded,
                      color: AppColors.blue,
                      isLoading: busy,
                      onPressed: _import,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  const _ExplainCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.backupExplain,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                height: 1.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _Card({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.h3)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
