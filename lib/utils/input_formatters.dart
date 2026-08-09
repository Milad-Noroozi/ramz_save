import 'package:flutter/services.dart';

import 'app_helper.dart';

/// Folds Persian (۰-۹) and Arabic (٠-٩) numerals to ASCII as the user types.
///
/// Card numbers, CVVs and expiry dates are *data* — they get parsed, checksummed
/// and read back off the screen. A Persian keyboard emits Persian numerals, so
/// without this a perfectly valid card number fails the Luhn check.
class LatinDigitsFormatter extends TextInputFormatter {
  const LatinDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final folded = AppHelper.toEnglishDigits(newValue.text);
    if (folded == newValue.text) return newValue;

    // Every Persian numeral is one code unit and maps to one ASCII digit, so
    // the length is unchanged and the selection carries over untouched.
    return newValue.copyWith(text: folded);
  }
}

/// Groups a card number into 4-digit blocks while keeping the caret where the
/// user left it.
class CardNumberFormatter extends TextInputFormatter {
  const CardNumberFormatter({this.maxDigits = 19});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = AppHelper.toEnglishDigits(
      newValue.text,
    ).replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;

    // Count digits left of the caret, then re-place it after that many digits
    // in the grouped string — otherwise inserting a space jumps the caret.
    final digitsBeforeCaret = AppHelper.toEnglishDigits(
      newValue.text.substring(0, newValue.selection.baseOffset.clamp(
        0,
        newValue.text.length,
      )),
    ).replaceAll(RegExp(r'\D'), '').length;

    final grouped = AppHelper.formatCardNumber(capped);

    var offset = 0;
    var seen = 0;
    while (offset < grouped.length && seen < digitsBeforeCaret) {
      if (grouped.codeUnitAt(offset) != 0x20) seen++;
      offset++;
    }

    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// `MM/YY`, with the slash inserted for the user.
class ExpiryDateFormatter extends TextInputFormatter {
  const ExpiryDateFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = AppHelper.toEnglishDigits(
      newValue.text,
    ).replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 4 ? digits.substring(0, 4) : digits;

    // Don't auto-insert while deleting: a user backspacing over "12/" would
    // otherwise have the slash typed straight back in.
    final deleting = newValue.text.length < oldValue.text.length;
    final text = capped.length <= 2
        ? capped + (capped.length == 2 && !deleting ? '/' : '')
        : '${capped.substring(0, 2)}/${capped.substring(2)}';

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
