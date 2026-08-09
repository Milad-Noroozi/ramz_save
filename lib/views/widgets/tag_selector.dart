import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../models/vault_model.dart';

extension VaultTagStyle on VaultTag {
  IconData get icon => switch (this) {
    VaultTag.browser => Icons.language_rounded,
    VaultTag.mobileApp => Icons.phone_iphone_rounded,
    VaultTag.payment => Icons.credit_card_rounded,
  };

  Color get color => switch (this) {
    VaultTag.browser => AppColors.blue,
    VaultTag.mobileApp => AppColors.purple,
    VaultTag.payment => AppColors.green,
  };
}

/// Multi-select tag chips for the add/edit form.
///
/// Wraps rather than scrolls: on a form the user needs to see every option at
/// once to decide, and there are only three.
class TagSelector extends StatelessWidget {
  final List<VaultTag> selected;
  final ValueChanged<List<VaultTag>> onChanged;

  /// Renders the `برچسب‌ها` caption above the chips.
  final bool showLabel;

  const TagSelector({
    required this.selected,
    required this.onChanged,
    this.showLabel = true,
    super.key,
  });

  void _toggle(VaultTag tag) {
    final next = [...selected];
    if (!next.remove(tag)) next.add(tag);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            children: [
              Text(AppStrings.tags, style: AppTextStyles.label),
              const SizedBox(width: 6),
              Text(
                '(${AppStrings.optional})',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in VaultTag.values)
              TagChip(
                tag: tag,
                selected: selected.contains(tag),
                onTap: () => _toggle(tag),
              ),
          ],
        ),
      ],
    );
  }
}

/// A single tag chip. Also used read-only on the detail sheet, where [onTap] is
/// left null.
class TagChip extends StatelessWidget {
  final VaultTag tag;
  final bool selected;
  final VoidCallback? onTap;

  const TagChip({
    required this.tag,
    this.selected = true,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = tag.color;

    final content = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 16,
            color: selected ? color : AppColors.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            tag.label,
            style: AppTextStyles.label.copyWith(
              color: selected ? color : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: selected
          ? color.withValues(alpha: 0.14)
          : AppColors.inputBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : Colors.transparent,
        ),
      ),
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}
