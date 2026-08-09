import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../utils/password_utils.dart';

/// Four segments that fill as the password gets stronger, with the bucket name
/// beside them.
///
/// Segments rather than one continuous bar: the score is a bucket, not a
/// percentage, and a smooth bar invites the user to read precision that isn't
/// there.
class PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;

  /// Hides the label, for the tight row under a text field.
  final bool showLabel;

  const PasswordStrengthBar({
    required this.strength,
    this.showLabel = true,
    super.key,
  });

  /// Builds from raw text, so callers don't each repeat the scoring call.
  PasswordStrengthBar.of(String password, {this.showLabel = true, super.key})
    : strength = PasswordUtils.estimate(password);

  @override
  Widget build(BuildContext context) {
    final color = AppColors.strengthColors[strength.index];
    final filled = strength.index + 1;
    final total = PasswordStrength.values.length;

    return Row(
      children: [
        // Segments fill from the start edge, which RTL puts on the right.
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i < filled ? color : AppColors.inputBg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i != total - 1) const SizedBox(width: 6),
        ],
        if (showLabel) ...[
          const SizedBox(width: 12),
          // A fixed box so the bar's width doesn't shift as the label changes
          // between "خوب" and "خیلی ضعیف".
          SizedBox(
            width: 64,
            child: Text(
              strength.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// The `قدرت رمز` caption plus the bar, as used on the generator screen.
class LabelledStrengthBar extends StatelessWidget {
  final PasswordStrength strength;

  const LabelledStrengthBar({required this.strength, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.strengthLabel, style: AppTextStyles.label),
        const SizedBox(height: 8),
        PasswordStrengthBar(strength: strength),
      ],
    );
  }
}
