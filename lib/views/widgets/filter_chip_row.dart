import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/vault_controller.dart';
import '../../utils/app_helper.dart';

extension on VaultFilter {
  String get label => switch (this) {
    VaultFilter.all => AppStrings.filterAll,
    VaultFilter.safe => AppStrings.filterSafe,
    VaultFilter.weak => AppStrings.filterWeak,
    VaultFilter.compromised => AppStrings.filterCompromised,
    VaultFilter.reused => AppStrings.filterReused,
  };

  /// Chips inherit the colour of the risk they filter to, so the palette
  /// carries the same meaning here as it does on the tiles.
  Color get color => switch (this) {
    VaultFilter.all => AppColors.purple,
    VaultFilter.safe => AppColors.green,
    VaultFilter.weak => AppColors.warning,
    VaultFilter.compromised => AppColors.error,
    VaultFilter.reused => AppColors.blue,
  };

  int countIn(VaultHealth health) => switch (this) {
    VaultFilter.all => health.total,
    VaultFilter.safe => health.safeCount,
    VaultFilter.weak => health.weakCount,
    VaultFilter.compromised => health.compromisedCount,
    VaultFilter.reused => health.reusedCount,
  };
}

/// The horizontally scrolling filter chips above the vault list.
///
/// Each chip carries its own count, which is what makes the row useful at a
/// glance — the user sees there are three weak passwords without tapping.
class FilterChipRow extends StatelessWidget {
  final VaultFilter selected;
  final VaultHealth health;
  final ValueChanged<VaultFilter> onSelected;

  /// Hides the trailing count, for rows where the numbers add noise.
  final bool showCounts;

  const FilterChipRow({
    required this.selected,
    required this.health,
    required this.onSelected,
    this.showCounts = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // No explicit reverse: the list follows the ambient direction, so RTL
        // starts it on the right on its own.
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        itemCount: VaultFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = VaultFilter.values[index];
          return _Chip(
            label: filter.label,
            color: filter.color,
            count: showCounts ? filter.countIn(health) : null,
            selected: filter == selected,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: selected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white.withValues(alpha: 0.22)
                        : color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppHelper.number(count!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected ? AppColors.white : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
