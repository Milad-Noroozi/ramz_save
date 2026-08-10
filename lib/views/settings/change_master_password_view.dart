import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/password_utils.dart';
import '../../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_bar.dart';

/// Changes the master password.
///
/// Cheap, despite appearances: the vault key itself never changes, so this only
/// re-wraps it under a key derived from the new password. Nothing is decrypted
/// and re-encrypted, and every saved entry is untouched.
class ChangeMasterPasswordView extends StatefulWidget {
  const ChangeMasterPasswordView({super.key});

  @override
  State<ChangeMasterPasswordView> createState() =>
      _ChangeMasterPasswordViewState();
}

class _ChangeMasterPasswordViewState extends State<ChangeMasterPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  PasswordStrength _strength = PasswordStrength.veryWeak;

  @override
  void initState() {
    super.initState();
    _next.addListener(() {
      final next = PasswordUtils.estimate(_next.text);
      if (next != _strength) setState(() => _strength = next);
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final changed = await auth.changeMasterPassword(
      current: _current.text,
      next: _next.text,
    );

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          changed
              ? AppStrings.masterPasswordChanged
              : (auth.error ?? AppStrings.genericError),
        ),
        backgroundColor: changed ? null : AppColors.error,
      ),
    );
    if (changed) navigator.pop();
  }

  String? _validateNext(String? value) {
    final base = Validators.masterPassword(value);
    if (base != null) return base;
    // A "change" that changes nothing is almost always a mistyped field.
    if (value == _current.text) return AppStrings.sameAsCurrentPassword;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthController, bool>((a) => a.isBusy);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.changeMasterPassword)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const _Notice(),
              const SizedBox(height: 26),

              CustomTextField.password(
                controller: _current,
                label: AppStrings.currentMasterPassword,
                hint: AppStrings.masterPasswordHint,
                textInputAction: TextInputAction.next,
                validator: Validators.required,
              ),
              const SizedBox(height: 20),

              CustomTextField.password(
                controller: _next,
                label: AppStrings.newMasterPassword,
                hint: AppStrings.masterPasswordHint,
                textInputAction: TextInputAction.next,
                validator: _validateNext,
                footer: PasswordStrengthBar(strength: _strength),
              ),
              const SizedBox(height: 20),

              CustomTextField.password(
                controller: _confirm,
                label: AppStrings.confirmMasterPassword,
                hint: AppStrings.confirmMasterPasswordHint,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.confirmPassword(v, _next.text),
                onSubmitted: busy ? null : _submit,
              ),
              const SizedBox(height: 30),

              CustomButton(
                text: AppStrings.changeMasterPassword,
                icon: Icons.key_rounded,
                isLoading: busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 20,
            color: AppColors.purple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.changeMasterPasswordNote,
              style: AppTextStyles.bodySmall.copyWith(height: 1.9),
            ),
          ),
        ],
      ),
    );
  }
}
