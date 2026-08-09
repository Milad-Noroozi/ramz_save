import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';

/// A section title with an optional "مشاهده همه" action on the far side.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onActionTap;
  final String actionLabel;

  const SectionHeader({
    required this.title,
    this.onActionTap,
    this.actionLabel = AppStrings.viewAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3),
        if (onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Points along the reading direction, so it aims left in
                  // Persian without a manual icon swap.
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.green,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A labelled value row, used on the detail sheet and the settings screens.
///
/// [latin] renders the value in its own left-to-right monospace island — the
/// same rule the text fields follow, so a password looks identical whether it
/// is being read or edited.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool latin;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const DetailRow({
    required this.label,
    required this.value,
    this.latin = false,
    this.icon,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      style: latin
          ? AppTextStyles.mono
          : AppTextStyles.bodyLarge,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: latin ? TextAlign.left : TextAlign.start,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.textHint),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  if (latin)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: valueWidget,
                      ),
                    )
                  else
                    valueWidget,
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
