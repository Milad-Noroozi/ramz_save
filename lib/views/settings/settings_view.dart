import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_routes.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/user_model.dart';
import '../../utils/app_helper.dart';

/// The settings hub.
///
/// Anything touching key material — the biometric copy of the vault key, the
/// master password — is delegated to [AuthController]; this screen only asks
/// and reports.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _toggleBiometric(BuildContext context, bool value) async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await auth.setBiometricEnabled(value);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (value
                    ? AppStrings.biometricEnabled
                    : AppStrings.biometricDisabled)
              : (auth.error ?? AppStrings.biometricFailed),
        ),
      ),
    );
  }

  Future<void> _pickAutoLock(BuildContext context) async {
    final settings = context.read<SettingsController>();
    final current = settings.autoLock;

    final choice = await showModalBottomSheet<AutoLockDuration>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(AppStrings.autoLock, style: AppTextStyles.h3),
            const SizedBox(height: 8),
            for (final option in AutoLockDuration.values)
              ListTile(
                onTap: () => Navigator.pop(context, option),
                title: Text(
                  AppHelper.toPersianDigits(option.label),
                  style: AppTextStyles.bodyLarge,
                ),
                trailing: option == current
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.purple,
                      )
                    : null,
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (choice != null) await settings.setAutoLock(choice);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.watch<AuthController>();
    final user = settings.user;
    final biometrics = auth.biometricAvailability;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ProfileCard(
              name: user?.name ?? '',
              email: user?.email,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            ),
            const SizedBox(height: 18),
            _PremiumBanner(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.premium),
            ),
            const SizedBox(height: 26),

            _Section(title: AppStrings.security),
            _SwitchTile(
              icon: Icons.fingerprint_rounded,
              title: AppStrings.useBiometric,
              // The hardware may be present but unusable — nothing enrolled, no
              // device lock. Saying which is more useful than a dead switch.
              subtitle: biometrics.isReady ? null : biometrics.message,
              value: settings.useBiometric,
              onChanged: biometrics.isReady && !auth.isBusy
                  ? (value) => _toggleBiometric(context, value)
                  : null,
            ),
            _Tile(
              icon: Icons.timer_outlined,
              title: AppStrings.autoLock,
              trailingText: AppHelper.toPersianDigits(settings.autoLock.label),
              onTap: () => _pickAutoLock(context),
            ),
            _Tile(
              icon: Icons.key_rounded,
              title: AppStrings.changeMasterPassword,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.changeMasterPassword),
            ),

            const SizedBox(height: 18),
            _Section(title: AppStrings.preferences),
            _SwitchTile(
              icon: Icons.cloud_outlined,
              title: AppStrings.checkBreaches,
              subtitle: AppStrings.checkBreachesDesc,
              value: settings.checkBreachesOnline,
              onChanged: settings.setCheckBreachesOnline,
            ),

            const SizedBox(height: 18),
            _Section(title: AppStrings.dataAndBackup),
            _Tile(
              icon: Icons.backup_outlined,
              title: AppStrings.backupAndRestore,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.backup),
            ),

            const SizedBox(height: 18),
            _Section(title: AppStrings.about),
            _Tile(
              icon: Icons.info_outline_rounded,
              title: AppStrings.version,
              trailingText: AppHelper.toPersianDigits(AppStrings.appVersion),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                AppStrings.aboutDescription,
                style: AppTextStyles.bodySmall.copyWith(height: 1.9),
              ),
            ),

            const SizedBox(height: 28),
            _Tile(
              icon: Icons.lock_outline,
              title: AppStrings.lockVaultNow,
              color: AppColors.error,
              onTap: () {
                // Pop first: this screen sits above the tab shell, and the gate
                // in main.dart replaces everything under it on lock.
                Navigator.of(context).pop();
                auth.lock();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.label.copyWith(color: AppColors.textHint),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String? email;
  final VoidCallback onTap;

  const _ProfileCard({required this.name, this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final address = email;

    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  AppHelper.initial(name),
                  style: AppTextStyles.h2.copyWith(color: AppColors.purple),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? AppStrings.personalInfo : name,
                      style: AppTextStyles.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      // An email is Latin data: without its own island the
                      // domain would render before the local part.
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            address,
                            style: AppTextStyles.mono.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // Directional endpoints, so the sweep runs with the reading direction
          // rather than against it in Persian.
          gradient: const LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [AppColors.purple, AppColors.blue],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.upgradeToPremium,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.white,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  final Color? color;

  const _Tile({
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.textSecondary;
    final label = trailingText;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
      leading: Icon(icon, color: accent, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(color: color)),
      trailing: label != null
          ? Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : onTap == null
          ? null
          : const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textHint,
              textDirection: TextDirection.rtl,
            ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
      secondary: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(height: 1.7),
              ),
            ),
      activeThumbColor: AppColors.white,
      activeTrackColor: AppColors.purple,
    );
  }
}
