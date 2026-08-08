import 'package:shamsi_date/shamsi_date.dart';

import '../config/app_strings.dart';

/// Persian formatting helpers.
///
/// The digit conversions here are for *display text only* — counters, dates,
/// percentages. Never run a password, email, URL or card number through
/// [toPersianDigits]: those are data, and rewriting their digits corrupts them.
class AppHelper {
  AppHelper._();

  static const _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  static const _monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  /// `"12 items"` → `"۱۲ items"`. Only ASCII digits are touched.
  static String toPersianDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(_persianDigits[rune - 0x30]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Inverse of [toPersianDigits]; also folds Arabic-Indic digits (٠-٩), which
  /// arrive from some Arabic keyboards, so numeric input parses either way.
  static String toEnglishDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.write(rune - 0x06F0); // Persian ۰-۹
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.write(rune - 0x0660); // Arabic ٠-٩
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// A plain number with Persian digits: `1404` → `"۱۴۰۴"`.
  static String number(num value) => toPersianDigits(value.toString());

  /// `"۱۴ مرداد ۱۴۰۴"`.
  static String formatJalali(DateTime date) {
    final j = Jalali.fromDateTime(date);
    return toPersianDigits('${j.day} ${_monthNames[j.month - 1]} ${j.year}');
  }

  /// `"۱۴۰۴/۰۵/۱۴"` — for tight spaces where the long form will not fit.
  static String formatJalaliShort(DateTime date) {
    final j = Jalali.fromDateTime(date);
    final m = j.month.toString().padLeft(2, '0');
    final d = j.day.toString().padLeft(2, '0');
    return toPersianDigits('${j.year}/$m/$d');
  }

  /// Coarse "time ago" label. Deliberately stops at years — a vault entry does
  /// not need minute precision once it is months old.
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return AppStrings.justNow;
    if (diff.inMinutes < 60) {
      return '${number(diff.inMinutes)} ${AppStrings.minutesAgo}';
    }
    if (diff.inHours < 24) {
      return '${number(diff.inHours)} ${AppStrings.hoursAgo}';
    }
    if (diff.inDays < 30) {
      return '${number(diff.inDays)} ${AppStrings.daysAgo}';
    }
    if (diff.inDays < 365) {
      return '${number(diff.inDays ~/ 30)} ${AppStrings.monthsAgo}';
    }
    return '${number(diff.inDays ~/ 365)} ${AppStrings.yearsAgo}';
  }

  /// `"۶۶٪"` — uses the Persian percent sign, which sits on the correct side
  /// in RTL text unlike the ASCII `%`.
  static String percent(num value) => '${number(value.round())}٪';

  /// Groups a card number into 4-digit blocks for display. Digits stay Latin:
  /// this is data the user may need to read off and type elsewhere.
  static String formatCardNumber(String raw) {
    final digits = toEnglishDigits(raw).replaceAll(RegExp(r'\D'), '');
    final blocks = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      final end = i + 4 <= digits.length ? i + 4 : digits.length;
      blocks.add(digits.substring(i, end));
    }
    return blocks.join(' ');
  }

  /// Last four digits, for list rows.
  static String maskCardNumber(String raw) {
    final digits = toEnglishDigits(raw).replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '••••';
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  /// Strips the scheme and any `www.` so list rows show `example.com` rather
  /// than `https://www.example.com/`.
  static String prettyHost(String url) {
    var s = url.trim();
    s = s.replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '');
    s = s.replaceFirst(RegExp(r'^www\.'), '');
    final slash = s.indexOf('/');
    if (slash != -1) s = s.substring(0, slash);
    return s;
  }

  /// First character of a service name, for the fallback avatar tile.
  static String initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '؟' : trimmed.substring(0, 1).toUpperCase();
  }
}
