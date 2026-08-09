import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

/// The lock screen.
///
/// Biometric unlock is offered but never forced: the master password always
/// works, because a fingerprint can be unavailable for reasons the user cannot
/// fix in the moment — a wet hand, a re-enrolled face, a replaced sensor.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _password = TextEditingController();
  final _focus = FocusNode();

  /// Guards the one automatic biometric attempt per mount. Without it, a
  /// cancelled prompt would be re-raised on the rebuild that cancelling causes.
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoPrompt());
  }

  @override
  void dispose() {
    _password.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _maybeAutoPrompt() async {
    if (_autoPrompted || !mounted) return;
    final auth = context.read<AuthController>();
    if (!auth.canUseBiometric) return;

    _autoPrompted = true;
    await auth.unlockWithBiometric();
  }

  Future<void> _unlock() async {
    if (_password.text.isEmpty) return;
    final auth = context.read<AuthController>();
    final ok = await auth.unlock(_password.text);

    if (!ok && mounted) {
      _password.clear();
      _focus.requestFocus();
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.resetVaultTitle),
        content: const Text(AppStrings.resetVaultMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthController>().resetEverything();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: AppColors.purple,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.loginTitle,
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.loginSubtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            CustomTextField.password(
              controller: _password,
              hint: AppStrings.masterPasswordHint,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: _unlock,
            ),

            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      auth.error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            CustomButton(
              text: AppStrings.unlock,
              isLoading: auth.isBusy,
              onPressed: _unlock,
            ),

            if (auth.canUseBiometric) ...[
              const SizedBox(height: 14),
              CustomButton.outlined(
                text: AppStrings.unlockWithBiometric,
                icon: Icons.fingerprint_rounded,
                onPressed: auth.isBusy ? null : auth.unlockWithBiometric,
              ),
            ],

            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: auth.isBusy ? null : _confirmReset,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textHint,
                ),
                child: Text(
                  AppStrings.forgotMasterPassword,
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textHint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
