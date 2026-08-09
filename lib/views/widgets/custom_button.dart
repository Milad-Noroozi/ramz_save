import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

/// The app's button, in the three weights the design uses.
///
/// Everything sizes to a 52pt tap target and a 12pt radius so buttons line up
/// with the text fields they sit under.
enum _ButtonKind { filled, outlined, plain }

class CustomButton extends StatelessWidget {
  final String text;

  /// `null` disables the button — the caller doesn't set a separate flag.
  final VoidCallback? onPressed;

  /// Swaps the label for a spinner while keeping the button's size, so the
  /// layout doesn't jump when an action starts.
  final bool isLoading;

  final bool fullWidth;
  final IconData? icon;

  /// Overrides the fill (filled) or the outline and label (outlined/plain) —
  /// used for the destructive "delete" actions.
  final Color? color;

  final _ButtonKind _kind;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.color,
    super.key,
  }) : _kind = _ButtonKind.filled;

  const CustomButton.outlined({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.color,
    super.key,
  }) : _kind = _ButtonKind.outlined;

  const CustomButton.plain({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
    this.color,
    super.key,
  }) : _kind = _ButtonKind.plain;

  static const _height = 52.0;
  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  @override
  Widget build(BuildContext context) {
    // A loading button is unpressable regardless of what the caller passed —
    // otherwise a double tap fires the action twice.
    final enabled = onPressed != null && !isLoading;
    final accent = color ?? AppColors.purple;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                _kind == _ButtonKind.filled ? AppColors.white : accent,
              ),
            ),
          )
        : _label(enabled, accent);

    final button = switch (_kind) {
      _ButtonKind.filled => ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: AppColors.inputBg,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.textHint,
          elevation: 0,
          shape: _shape,
        ),
        child: child,
      ),
      _ButtonKind.outlined => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          disabledForegroundColor: AppColors.textHint,
          side: BorderSide(
            color: enabled ? accent : AppColors.divider,
          ),
          shape: _shape,
        ),
        child: child,
      ),
      _ButtonKind.plain => TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: accent,
          disabledForegroundColor: AppColors.textHint,
          shape: _shape,
        ),
        child: child,
      ),
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: button,
    );
  }

  Widget _label(bool enabled, Color accent) {
    final style = AppTextStyles.button.copyWith(
      color: !enabled
          ? AppColors.textHint
          : _kind == _ButtonKind.filled
          ? AppColors.white
          : accent,
    );

    if (icon == null) return Text(text, style: style);

    // The icon leads in reading order, so it sits on the right in RTL. Row
    // handles that on its own — no manual side-swapping.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: style.color),
        const SizedBox(width: 8),
        Text(text, style: style),
      ],
    );
  }
}
