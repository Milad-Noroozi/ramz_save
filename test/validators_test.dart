import 'package:flutter_test/flutter_test.dart';
import 'package:ramz_save/config/app_strings.dart';
import 'package:ramz_save/utils/validators.dart';

/// Form validation. The recurring theme: a Persian keyboard must never be the
/// reason a valid value is rejected.
void main() {
  group('masterPassword', () {
    test('accepts eight characters or more', () {
      expect(Validators.masterPassword('hunter2!x'), isNull);
    });

    test('rejects empty and short', () {
      expect(Validators.masterPassword(''), AppStrings.fieldRequired);
      expect(Validators.masterPassword('short'), AppStrings.passwordTooShort);
    });

    test('does not trim — a leading space is part of the password', () {
      // Trimming here would silently change the key the user chose, and the
      // vault would then refuse the password they think they set.
      expect(Validators.masterPassword(' 1234567'), isNull);
    });
  });

  group('confirmPassword', () {
    test('must match exactly', () {
      expect(Validators.confirmPassword('abcd1234', 'abcd1234'), isNull);
      expect(
        Validators.confirmPassword('abcd1234', 'abcd12345'),
        AppStrings.passwordsDoNotMatch,
      );
    });
  });

  group('email', () {
    test('blank passes — the field is optional', () {
      expect(Validators.email(''), isNull);
      expect(Validators.email('   '), isNull);
    });

    test('accepts ordinary addresses', () {
      expect(Validators.email('milad@example.com'), isNull);
      expect(Validators.email('a.b+tag@mail.co.ir'), isNull);
    });

    test('rejects malformed ones', () {
      expect(Validators.email('milad@'), AppStrings.invalidEmail);
      expect(Validators.email('milad@example'), AppStrings.invalidEmail);
      expect(Validators.email('@example.com'), AppStrings.invalidEmail);
    });
  });

  group('loginIdentifier', () {
    test('a bare username passes', () {
      // The login field takes either; only presence is required unless it
      // looks like an address.
      expect(Validators.loginIdentifier('milad_n'), isNull);
    });

    test('something containing @ is held to the email shape', () {
      expect(Validators.loginIdentifier('milad@'), AppStrings.invalidEmail);
    });

    test('empty is rejected', () {
      expect(Validators.loginIdentifier(''), AppStrings.fieldRequired);
    });
  });

  group('url', () {
    test('blank passes', () {
      expect(Validators.url(''), isNull);
    });

    test('a bare host is accepted — the scheme is assumed', () {
      expect(Validators.url('example.com'), isNull);
      expect(Validators.url('https://www.example.com/login'), isNull);
    });

    test('a hostless string is rejected', () {
      expect(Validators.url('not a url'), AppStrings.invalidUrl);
      expect(Validators.url('localhost'), AppStrings.invalidUrl);
    });
  });

  group('cardNumber', () {
    // An Iranian card BIN with a correct Luhn check digit.
    const valid = '6037991199001128';

    test('accepts a Luhn-valid number', () {
      expect(Validators.cardNumber(valid), isNull);
    });

    test('accepts the same number typed on a Persian keyboard', () {
      expect(Validators.cardNumber('۶۰۳۷۹۹۱۱۹۹۰۰۱۱۲۸'), isNull);
    });

    test('accepts it with display grouping', () {
      expect(Validators.cardNumber('6037 9911 9900 1128'), isNull);
    });

    test('catches a transposition that a length check would pass', () {
      // 28 → 82 in the last block. Same length, wrong checksum.
      expect(
        Validators.cardNumber('6037991199001182'),
        AppStrings.invalidCardNumber,
      );
    });

    test('rejects wrong lengths', () {
      expect(Validators.cardNumber('12345'), AppStrings.invalidCardNumber);
      expect(Validators.cardNumber(''), AppStrings.fieldRequired);
    });
  });

  group('expiryDate', () {
    String future() {
      final d = DateTime.now();
      return '12/${(d.year + 3) % 100}';
    }

    test('accepts a future MM/YY', () {
      expect(Validators.expiryDate(future()), isNull);
    });

    test('accepts Persian digits', () {
      final d = DateTime.now();
      final year = ((d.year + 3) % 100).toString();
      final persian = year.replaceAllMapped(
        RegExp(r'\d'),
        (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)],
      );
      expect(Validators.expiryDate('۱۲/$persian'), isNull);
    });

    test('the current month is still valid — cards expire at its end', () {
      final now = DateTime.now();
      final mm = now.month.toString().padLeft(2, '0');
      expect(Validators.expiryDate('$mm/${now.year % 100}'), isNull);
    });

    test('rejects a past date and a nonsense month', () {
      expect(Validators.expiryDate('01/20'), AppStrings.invalidExpiry);
      expect(Validators.expiryDate('13/30'), AppStrings.invalidExpiry);
      expect(Validators.expiryDate('1230'), AppStrings.invalidExpiry);
    });
  });

  group('cvv', () {
    test('accepts three or four digits, in either script', () {
      expect(Validators.cvv('123'), isNull);
      expect(Validators.cvv('1234'), isNull);
      expect(Validators.cvv('۱۲۳'), isNull);
    });

    test('rejects other lengths and non-digits', () {
      expect(Validators.cvv('12'), AppStrings.invalidCvv);
      expect(Validators.cvv('12345'), AppStrings.invalidCvv);
      expect(Validators.cvv('12a'), AppStrings.invalidCvv);
    });
  });

  group('phone', () {
    test('blank passes — the field is optional', () {
      expect(Validators.phone(''), isNull);
    });

    test('accepts Iranian mobiles in either script and with separators', () {
      expect(Validators.phone('09123456789'), isNull);
      expect(Validators.phone('۰۹۱۲۳۴۵۶۷۸۹'), isNull);
      expect(Validators.phone('0912 345-6789'), isNull);
    });

    test('rejects too-short input and letters', () {
      expect(Validators.phone('12345'), AppStrings.invalidPhone);
      expect(Validators.phone('0912abcdefg'), AppStrings.invalidPhone);
    });
  });
}
