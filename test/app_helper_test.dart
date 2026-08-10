import 'package:flutter_test/flutter_test.dart';
import 'package:ramz_save/utils/app_helper.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// The Persian display layer. The interesting cases are all about the boundary
/// between *text* (which gets Persian digits) and *data* (which must not).
void main() {
  group('toPersianDigits', () {
    test('converts ASCII digits and leaves everything else alone', () {
      expect(AppHelper.toPersianDigits('1404'), '۱۴۰۴');
      expect(AppHelper.toPersianDigits('۱۲ مورد'), '۱۲ مورد');
      expect(AppHelper.toPersianDigits('12 items'), '۱۲ items');
    });

    test('is reversible', () {
      expect(AppHelper.toEnglishDigits(AppHelper.toPersianDigits('9876543210')),
          '9876543210');
    });
  });

  group('toEnglishDigits', () {
    test('folds Persian digits', () {
      expect(AppHelper.toEnglishDigits('۰۹۱۲۳۴۵۶۷۸۹'), '09123456789');
    });

    test('folds Arabic-Indic digits, which some keyboards send instead', () {
      // ٠-٩ is a different code block from ۰-۹. A user on an Arabic layout
      // typing a card number would otherwise fail Luhn on every digit.
      expect(AppHelper.toEnglishDigits('٦٠٣٧'), '6037');
    });

    test('mixed input normalises to one script', () {
      expect(AppHelper.toEnglishDigits('۶۰۳۷-٩٩١-1234'), '6037-991-1234');
    });
  });

  group('number and percent', () {
    test('number renders in Persian digits', () {
      expect(AppHelper.number(0), '۰');
      expect(AppHelper.number(42), '۴۲');
    });

    test('percent rounds and uses the Persian sign', () {
      // The ASCII '%' lands on the wrong side of the number in RTL text.
      expect(AppHelper.percent(66.4), '۶۶٪');
      expect(AppHelper.percent(66.6), '۶۷٪');
    });
  });

  group('Jalali formatting', () {
    // 2025-08-05 Gregorian is 14 Mordad 1404.
    final date = Jalali(1404, 5, 14).toDateTime();

    test('long form names the month', () {
      expect(AppHelper.formatJalali(date), '۱۴ مرداد ۱۴۰۴');
    });

    test('short form zero-pads', () {
      expect(AppHelper.formatJalaliShort(date), '۱۴۰۴/۰۵/۱۴');
    });

    test('a single-digit month and day still pad in the short form', () {
      final early = Jalali(1403, 1, 5).toDateTime();
      expect(AppHelper.formatJalaliShort(early), '۱۴۰۳/۰۱/۰۵');
    });
  });

  group('relativeTime', () {
    test('buckets by the largest unit that fits', () {
      final now = DateTime.now();

      expect(AppHelper.relativeTime(now), 'همین الان');
      expect(
        AppHelper.relativeTime(now.subtract(const Duration(minutes: 5))),
        '۵ دقیقه پیش',
      );
      expect(
        AppHelper.relativeTime(now.subtract(const Duration(hours: 3))),
        '۳ ساعت پیش',
      );
      expect(
        AppHelper.relativeTime(now.subtract(const Duration(days: 2))),
        '۲ روز پیش',
      );
      expect(
        AppHelper.relativeTime(now.subtract(const Duration(days: 400))),
        '۱ سال پیش',
      );
    });
  });

  group('card numbers', () {
    test('grouping keeps the digits Latin', () {
      // The user reads this off the screen to type somewhere else. Persian
      // digits here would be actively harmful.
      expect(
        AppHelper.formatCardNumber('6037991234567890'),
        '6037 9912 3456 7890',
      );
    });

    test('grouping normalises Persian input first', () {
      expect(
        AppHelper.formatCardNumber('۶۰۳۷۹۹۱۲۳۴۵۶۷۸۹۰'),
        '6037 9912 3456 7890',
      );
    });

    test('a partial number groups what it has', () {
      expect(AppHelper.formatCardNumber('603799'), '6037 99');
    });

    test('masking shows only the last four', () {
      expect(AppHelper.maskCardNumber('6037991234567890'), '•••• 7890');
      expect(AppHelper.maskCardNumber('12'), '••••');
    });
  });

  group('prettyHost', () {
    test('strips scheme, www and path', () {
      expect(AppHelper.prettyHost('https://www.example.com/login'),
          'example.com');
      expect(AppHelper.prettyHost('http://sub.example.ir'), 'sub.example.ir');
      expect(AppHelper.prettyHost('example.com'), 'example.com');
    });
  });

  group('initial', () {
    test('takes the first character, uppercased', () {
      expect(AppHelper.initial('instagram'), 'I');
      expect(AppHelper.initial('  دیجی‌کالا'), 'د');
    });

    test('an empty name falls back to a question mark', () {
      expect(AppHelper.initial('   '), '؟');
    });
  });
}
