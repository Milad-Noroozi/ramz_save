import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../utils/app_helper.dart';
import '../../utils/input_formatters.dart';
import '../../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

/// The user's own details. None of this is used to unlock anything — it only
/// labels the vault — so all three fields are free-form and two are optional.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final current = auth.user;
    if (current == null) return;

    final email = _email.text.trim();
    final phone = AppHelper.toEnglishDigits(_phone.text).trim();

    // Built field by field rather than through copyWith: that helper reads a
    // null as "leave it alone", so it could never clear an email the user erased.
    await auth.updateUser(
      UserModel(
        name: _name.text.trim(),
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        useBiometric: current.useBiometric,
        autoLock: current.autoLock,
        checkBreachesOnline: current.checkBreachesOnline,
        createdAt: current.createdAt,
      ),
    );

    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.profileSaved)),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final createdAt = auth.user?.createdAt;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.personalInfo)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(child: _Avatar(name: _name.text)),
              const SizedBox(height: 26),

              CustomTextField(
                controller: _name,
                label: AppStrings.name,
                hint: AppStrings.yourNameHint,
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: Validators.required,
                // Redraws the initial inside the avatar as the name is typed.
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _email,
                label: '${AppStrings.email} (${AppStrings.optional})',
                hint: AppStrings.loginHint,
                latin: true,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phone,
                label: '${AppStrings.phone} (${AppStrings.optional})',
                hint: '۰۹۱۲۳۴۵۶۷۸۹',
                latin: true,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                maxLength: 11,
                // Folds a Persian keypad's digits to ASCII, so the validator
                // sees ۰۹۱۲… as 0912… rather than rejecting it.
                inputFormatters: [LatinDigitsFormatter()],
                validator: Validators.phone,
                onSubmitted: _save,
              ),

              if (createdAt != null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${AppStrings.createdOn} '
                      '${AppHelper.formatJalali(createdAt)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 30),
              CustomButton(
                text: AppStrings.save,
                icon: Icons.check_rounded,
                isLoading: auth.isBusy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        AppHelper.initial(name),
        style: AppTextStyles.h1.copyWith(color: AppColors.purple),
      ),
    );
  }
}
