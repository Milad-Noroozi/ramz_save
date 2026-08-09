import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/password_generator_controller.dart';
import '../../models/password_model.dart';
import '../../utils/app_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/password_strength_bar.dart';
import 'add_vault_view.dart';

/// Generates a password from the saved options and hands it to a new entry.
///
/// Every switch regenerates immediately, so what is on screen always matches
/// the rules above it — the user never copies a password built under settings
/// they have since changed.
class PasswordGeneratorView extends StatefulWidget {
  const PasswordGeneratorView({super.key});

  @override
  State<PasswordGeneratorView> createState() => _PasswordGeneratorViewState();
}

class _PasswordGeneratorViewState extends State<PasswordGeneratorView> {
  @override
  void initState() {
    super.initState();
    // After the first frame: `start()` notifies listeners, and doing that while
    // the tree is still building would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PasswordGeneratorController>().start();
    });
  }

  Future<void> _copy(PasswordGeneratorController generator) async {
    await generator.copy();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '${AppStrings.passwordCopied} — ${AppStrings.clipboardAutoClear}',
        ),
      ),
    );
  }

  void _saveToVault(String password) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddVaultView(initialPassword: password),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generator = context.watch<PasswordGeneratorController>();
    final options = generator.options;
    final hasPassword = generator.password.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(AppStrings.generatorTitle, style: AppTextStyles.h2),
            const SizedBox(height: 20),

            _PasswordCard(
              password: generator.password,
              copied: generator.copied,
              onCopy: hasPassword ? () => _copy(generator) : null,
              onRegenerate: options.hasAnyCharSet
                  ? generator.regenerate
                  : null,
            ),
            const SizedBox(height: 18),

            LabelledStrengthBar(strength: generator.strength),
            const SizedBox(height: 28),

            _LengthSlider(
              length: options.length,
              onChanged: generator.setLength,
            ),
            const SizedBox(height: 24),

            Text(AppStrings.options, style: AppTextStyles.label),
            const SizedBox(height: 4),
            _OptionSwitch(
              label: AppStrings.optLowercase,
              value: options.lowercase,
              onChanged: generator.toggleLowercase,
            ),
            _OptionSwitch(
              label: AppStrings.optUppercase,
              value: options.uppercase,
              onChanged: generator.toggleUppercase,
            ),
            _OptionSwitch(
              label: AppStrings.optDigits,
              value: options.digits,
              onChanged: generator.toggleDigits,
            ),
            _OptionSwitch(
              label: AppStrings.optSymbols,
              value: options.symbols,
              onChanged: generator.toggleSymbols,
            ),
            _OptionSwitch(
              label: AppStrings.optNoAmbiguous,
              value: options.excludeAmbiguous,
              onChanged: generator.toggleExcludeAmbiguous,
            ),

            if (!options.hasAnyCharSet) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.atLeastOneCharSet,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            CustomButton(
              text: AppStrings.savePassword,
              icon: Icons.shield_outlined,
              onPressed: hasPassword
                  ? () => _saveToVault(generator.password)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The generated password, shown large enough to read off the screen.
class _PasswordCard extends StatelessWidget {
  final String password;
  final bool copied;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;

  const _PasswordCard({
    required this.password,
    required this.copied,
    this.onCopy,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.yourNewPassword, style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          // The island: a generated password is Latin data, and it must wrap
          // and read left-to-right no matter what the page around it does.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SelectableText(
                password.isEmpty ? '—' : password,
                style: AppTextStyles.mono.copyWith(
                  fontSize: 20,
                  height: 1.5,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton.outlined(
                  text: copied ? AppStrings.copied : AppStrings.copy,
                  icon: copied ? Icons.check_rounded : Icons.copy_rounded,
                  color: copied ? AppColors.green : null,
                  onPressed: onCopy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: AppStrings.regenerate,
                  icon: Icons.refresh_rounded,
                  onPressed: onRegenerate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LengthSlider extends StatelessWidget {
  final int length;
  final ValueChanged<int> onChanged;

  const _LengthSlider({required this.length, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(AppStrings.passwordLength, style: AppTextStyles.label),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppHelper.number(length),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        // The slider mirrors itself under RTL, so the minimum sits on the right
        // and dragging inward raises the value — the direction the user reads.
        Slider(
          value: length.toDouble(),
          min: PasswordOptions.minLength.toDouble(),
          max: PasswordOptions.maxLength.toDouble(),
          divisions: PasswordOptions.maxLength - PasswordOptions.minLength,
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
      // Left in the ambient RTL: these labels are Persian with a short Latin
      // sample like "(a-z)" inside. Unicode bidi already places that run
      // correctly, and forcing the whole string to LTR would move the
      // parenthetical to the front and reverse the Persian around it.
      title: Text(label, style: AppTextStyles.bodyLarge),
      activeThumbColor: AppColors.white,
      activeTrackColor: AppColors.purple,
    );
  }
}
