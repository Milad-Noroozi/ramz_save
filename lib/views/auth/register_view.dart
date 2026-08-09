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

/// First run: choose a name and a master password.
///
/// The warning is not decoration. There is no recovery path by design — the
/// master password is never stored, so nothing on the device or anywhere else
/// can reconstruct it. The user has to understand that before they commit.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  PasswordStrength _strength = PasswordStrength.veryWeak;
  bool _acknowledged = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() {
      final next = PasswordUtils.estimate(_password.text);
      if (next != _strength) setState(() => _strength = next);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acknowledged) return;

    final auth = context.read<AuthController>();
    final created = await auth.createVault(
      name: _name.text.trim(),
      password: _password.text,
    );

    // The gate in main.dart routes on status, so a successful setup needs no
    // navigation here — only a failure needs saying out loud.
    if (!created && mounted) {
      final message = auth.error ?? AppStrings.genericError;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthController, bool>((a) => a.isBusy);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              const _Header(),
              const SizedBox(height: 32),

              CustomTextField(
                controller: _name,
                label: AppStrings.yourName,
                hint: AppStrings.yourNameHint,
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: Validators.required,
              ),
              const SizedBox(height: 20),

              CustomTextField.password(
                controller: _password,
                label: AppStrings.masterPassword,
                hint: AppStrings.masterPasswordHint,
                textInputAction: TextInputAction.next,
                validator: Validators.masterPassword,
                footer: PasswordStrengthBar(strength: _strength),
              ),
              const SizedBox(height: 20),

              CustomTextField.password(
                controller: _confirm,
                label: AppStrings.confirmMasterPassword,
                hint: AppStrings.confirmMasterPasswordHint,
                textInputAction: TextInputAction.done,
                onSubmitted: busy ? null : _submit,
                validator: (v) =>
                    Validators.confirmPassword(v, _password.text),
              ),
              const SizedBox(height: 24),

              _WarningBox(
                checked: _acknowledged,
                onChanged: (v) => setState(() => _acknowledged = v),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: AppStrings.createVault,
                isLoading: busy,
                // Gated on the acknowledgement, not just the form: an
                // unrecoverable password deserves a deliberate second action.
                onPressed: _acknowledged ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 32,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(height: 20),
        Text(AppStrings.registerTitle, style: AppTextStyles.h1),
        const SizedBox(height: 10),
        Text(
          AppStrings.registerSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
        ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _WarningBox({required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: checked ? 0.6 : 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.warning,
                checkColor: AppColors.black,
                side: const BorderSide(color: AppColors.warning),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.registerWarning,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
