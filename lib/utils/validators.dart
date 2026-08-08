import '../config/app_strings.dart';
import 'app_helper.dart';

/// Form validators. Each returns `null` when the value is acceptable and a
/// Persian message otherwise, matching `TextFormField.validator`.
///
/// Every validator that reads digits folds Persian/Arabic numerals to ASCII
/// first, so a user typing on a Persian keyboard is never rejected for it.
class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  static String? masterPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 8) return AppStrings.passwordTooShort;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value != original) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  /// Optional field: blank passes, anything present must look like an address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final ok = RegExp(
      r'^[\w.!#$%&*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$',
    ).hasMatch(value.trim());
    return ok ? null : AppStrings.invalidEmail;
  }

  /// The login field accepts either an email or a bare username, so it only
  /// enforces presence — and validates shape when it *looks* like an email.
  static String? loginIdentifier(String? value) {
    final missing = required(value);
    if (missing != null) return missing;
    if (value!.contains('@')) return email(value);
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim();
    final withScheme = text.contains('://') ? text : 'https://$text';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return AppStrings.invalidUrl;
    }
    return null;
  }

  /// Length plus Luhn checksum — catches transposed digits, which a length
  /// check alone would pass.
  static String? cardNumber(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final digits = AppHelper.toEnglishDigits(
      value,
    ).replaceAll(RegExp(r'\D'), '');
    if (digits.length < 12 || digits.length > 19) {
      return AppStrings.invalidCardNumber;
    }
    return _luhnValid(digits) ? null : AppStrings.invalidCardNumber;
  }

  static bool _luhnValid(String digits) {
    var sum = 0;
    var double = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = digits.codeUnitAt(i) - 0x30;
      if (double) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      double = !double;
    }
    return sum % 10 == 0;
  }

  /// `MM/YY` or `MM/YYYY`, and the date must not already be past.
  static String? expiryDate(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final text = AppHelper.toEnglishDigits(value.trim());
    final match = RegExp(r'^(\d{1,2})\s*/\s*(\d{2}|\d{4})$').firstMatch(text);
    if (match == null) return AppStrings.invalidExpiry;

    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return AppStrings.invalidExpiry;

    var year = int.parse(match.group(2)!);
    if (year < 100) year += 2000;

    // Cards stay valid through the last day of their expiry month.
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    if (endOfMonth.isBefore(DateTime.now())) return AppStrings.invalidExpiry;
    return null;
  }

  static String? cvv(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final digits = AppHelper.toEnglishDigits(value.trim());
    final ok = RegExp(r'^\d{3,4}$').hasMatch(digits);
    return ok ? null : AppStrings.invalidCvv;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = AppHelper.toEnglishDigits(
      value,
    ).replaceAll(RegExp(r'[\s()-]'), '');
    final ok = RegExp(r'^(\+?\d{1,4})?\d{7,12}$').hasMatch(digits);
    return ok ? null : AppStrings.invalidPhone;
  }
}
