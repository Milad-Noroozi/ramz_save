import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../widgets/custom_button.dart';

/// The upgrade pitch.
///
/// Presentation only — there is no billing integration behind it, and the note
/// at the bottom says so rather than letting the screen imply a purchase it
/// cannot make.
class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  _Plan _selected = _Plan.yearly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.premiumTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _Crown(),
            const SizedBox(height: 24),

            Text(
              AppStrings.premiumTitle,
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.premiumTrial,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            const _Perk(text: AppStrings.premiumPerk1),
            const _Perk(text: AppStrings.premiumPerk2),
            const _Perk(text: AppStrings.premiumPerk3),
            const SizedBox(height: 28),

            for (final plan in _Plan.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(
                  plan: plan,
                  selected: plan == _selected,
                  onTap: () => setState(() => _selected = plan),
                ),
              ),
            const SizedBox(height: 18),

            CustomButton(
              text: AppStrings.goPremium,
              icon: Icons.workspace_premium_rounded,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.premiumDemoNote)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.premiumDemoNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _Plan {
  yearly(AppStrings.premiumYearly, '۲۹۹٬۰۰۰', AppStrings.perYear),
  weekly(AppStrings.premiumWeekly, '۱۹٬۰۰۰', AppStrings.perWeek);

  final String label;
  final String price;
  final String period;

  const _Plan(this.label, this.price, this.period);
}

class _Crown extends StatelessWidget {
  const _Crown();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Directional endpoints so the sweep follows the reading direction.
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [AppColors.purple, AppColors.blue],
          ),
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          size: 48,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final String text;

  const _Perk({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.12)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.divider,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: selected ? AppColors.purple : AppColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                plan.label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // The price is already written in Persian digits above, so it needs
            // no conversion here — only the currency word beside it.
            Text(
              '${plan.price} ${AppStrings.toman}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: selected ? AppColors.purple : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(plan.period, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
