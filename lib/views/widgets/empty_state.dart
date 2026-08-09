import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import 'custom_button.dart';

/// The "nothing here yet" placeholder, used by the vault list, search results
/// and the health screen.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Icon on the action button. Defaults to a plus, since most empty states
  /// here invite the user to create something.
  final IconData actionIcon;

  /// Tints the icon — green on the health screen, where "empty" is good news.
  final Color? color;

  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.purple;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
                icon: actionIcon,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
