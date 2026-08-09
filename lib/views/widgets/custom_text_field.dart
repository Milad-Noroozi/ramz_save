import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_strings.dart';
import '../../utils/input_formatters.dart';

/// The app's text input: a right-aligned Persian label above a filled field.
///
/// ## The LTR island
///
/// Passwords, emails, URLs and card numbers are Latin *data* sitting inside a
/// right-to-left page. Left to the ambient direction, `user@mail.com` renders as
/// `com.mail@user` and a card number reads backwards. Passing [latin] renders
/// the value left-to-right in a monospace face, so `l`/`1` and `O`/`0` stay
/// apart when the user reads a password off the screen.
///
/// The direction flips only once there is text: while the field is empty the
/// Persian hint still sits on the right where it belongs.
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;

  /// Renders the value left-to-right in monospace. See the class docs.
  final bool latin;

  /// Starts obscured and adds the reveal toggle.
  final bool isPassword;

  final IconData? icon;

  /// Sits at the end of the field, after the reveal toggle if there is one.
  final Widget? trailing;

  /// A tappable row under the field — "ساخت رمز قوی" on the password field.
  final Widget? footer;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const CustomTextField({
    this.controller,
    this.label,
    this.hint,
    this.latin = false,
    this.isPassword = false,
    this.icon,
    this.trailing,
    this.footer,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.onTap,
    super.key,
  });

  /// Obscured, LTR, monospace, and kept out of autocorrect and suggestions.
  const CustomTextField.password({
    this.controller,
    this.label = AppStrings.password,
    this.hint = AppStrings.passwordHint,
    this.trailing,
    this.footer,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    super.key,
  }) : latin = true,
       isPassword = true,
       icon = Icons.lock_outline,
       keyboardType = null,
       inputFormatters = null,
       maxLines = 1,
       maxLength = null,
       readOnly = false,
       onTap = null;

  /// Digits only, folded to ASCII so a Persian keyboard still validates.
  const CustomTextField.numeric({
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.trailing,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    super.key,
  }) : latin = true,
       isPassword = false,
       footer = null,
       keyboardType = TextInputType.number,
       maxLines = 1,
       readOnly = false,
       onTap = null;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  bool _obscured = true;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // Only dispose what this widget created — a caller's controller usually
    // outlives the field and disposing it here would break the next build.
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Latin data reads left-to-right, but only once there is data: an empty
  /// field should leave its Persian hint on the right.
  bool get _asLatin => widget.latin && _hasText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.label),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          onTap: widget.onTap,
          obscureText: widget.isPassword && _obscured,
          obscuringCharacter: '•',

          // Secrets must not reach the keyboard's learned-words store or a
          // suggestion strip that another app can read.
          enableSuggestions: !widget.isPassword,
          autocorrect: !widget.isPassword,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: [
            ...?widget.inputFormatters,
            if (widget.keyboardType == TextInputType.number &&
                widget.inputFormatters == null)
              const LatinDigitsFormatter(),
          ],
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          textDirection: _asLatin ? TextDirection.ltr : null,
          textAlign: _asLatin ? TextAlign.left : TextAlign.start,
          style: widget.latin ? AppTextStyles.mono : AppTextStyles.bodyLarge,
          cursorColor: AppColors.purple,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            // The hint is Persian even on Latin fields, so it keeps its own
            // direction regardless of what the value does.
            hintTextDirection: TextDirection.rtl,
            counterText: '',
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20, color: AppColors.textHint),
            suffixIcon: _buildSuffix(),
          ),
        ),
        if (widget.footer != null) ...[
          const SizedBox(height: 8),
          widget.footer!,
        ],
      ],
    );
  }

  Widget? _buildSuffix() {
    final toggle = widget.isPassword
        ? IconButton(
            onPressed: () => setState(() => _obscured = !_obscured),
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.textHint,
            ),
            tooltip: _obscured ? AppStrings.password : AppStrings.close,
          )
        : null;

    if (toggle == null) return widget.trailing;
    if (widget.trailing == null) return toggle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [toggle, widget.trailing!],
    );
  }
}
