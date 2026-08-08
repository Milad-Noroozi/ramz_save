import 'dart:math';

import '../config/app_strings.dart';

/// Strength buckets. The order matters: `index` is used to look up a colour in
/// `AppColors.strengthColors`, and health screens compare with `<`.
enum PasswordStrength {
  veryWeak,
  weak,
  good,
  strong;

  String get label => switch (this) {
    PasswordStrength.veryWeak => AppStrings.strengthVeryWeak,
    PasswordStrength.weak => AppStrings.strengthWeak,
    PasswordStrength.good => AppStrings.strengthGood,
    PasswordStrength.strong => AppStrings.strengthStrong,
  };

  /// Fraction of the strength bar to fill, 0..1.
  double get fraction => (index + 1) / PasswordStrength.values.length;
}

/// Character sets used for both generation and strength scoring.
class CharSets {
  CharSets._();

  static const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const digits = '0123456789';
  static const symbols = '!@#\$%^&*()-_=+[]{};:,.<>?';

  /// Glyphs that are easy to confuse when read off a screen.
  static const ambiguous = 'lI1O0o';
}

class PasswordUtils {
  PasswordUtils._();

  /// Cryptographically secure source. The previous implementation used
  /// `Random()`, which is seeded predictably and must never generate secrets.
  static final Random _secureRandom = Random.secure();

  /// Builds a password from the enabled character sets.
  ///
  /// Guarantees at least one character from every enabled set, then shuffles,
  /// so a 20-character password can't come out digit-free by chance.
  ///
  /// Throws [ArgumentError] if no set is enabled or [length] cannot fit one
  /// character from each.
  static String generate({
    int length = 16,
    bool lowercase = true,
    bool uppercase = true,
    bool digits = true,
    bool symbols = false,
    bool excludeAmbiguous = false,
  }) {
    final pools = <String>[
      if (lowercase) CharSets.lowercase,
      if (uppercase) CharSets.uppercase,
      if (digits) CharSets.digits,
      if (symbols) CharSets.symbols,
    ].map((pool) {
      if (!excludeAmbiguous) return pool;
      return pool
          .split('')
          .where((c) => !CharSets.ambiguous.contains(c))
          .join();
    }).where((pool) => pool.isNotEmpty).toList();

    if (pools.isEmpty) {
      throw ArgumentError(AppStrings.atLeastOneCharSet);
    }
    if (length < pools.length) {
      throw ArgumentError('length must be at least ${pools.length}');
    }

    final all = pools.join();
    final chars = <String>[
      // One guaranteed character per enabled set…
      for (final pool in pools) pool[_secureRandom.nextInt(pool.length)],
      // …then fill the remainder from the combined pool.
      for (var i = pools.length; i < length; i++)
        all[_secureRandom.nextInt(all.length)],
    ];

    _secureShuffle(chars);
    return chars.join();
  }

  /// Fisher-Yates driven by the secure RNG. `List.shuffle` defaults to the
  /// insecure generator unless one is passed, so this is not just ceremony.
  static void _secureShuffle(List<String> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _secureRandom.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  /// Search-space entropy in bits: `length * log2(alphabet size)`.
  ///
  /// This measures the password *as generated*. It knowingly over-rates
  /// human-chosen passwords like `Password123!`, which is why [estimate]
  /// applies penalties on top rather than reading this number alone.
  static double entropyBits(String password) {
    if (password.isEmpty) return 0;

    var alphabet = 0;
    if (password.contains(RegExp(r'[a-z]'))) alphabet += 26;
    if (password.contains(RegExp(r'[A-Z]'))) alphabet += 26;
    if (password.contains(RegExp(r'[0-9]'))) alphabet += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) alphabet += 32;

    if (alphabet == 0) return 0;
    return password.length * (log(alphabet) / log(2));
  }

  /// Scores a password, discounting patterns that inflate raw entropy.
  static PasswordStrength estimate(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;

    var bits = entropyBits(password);

    // A password that is only one long run of repeats ("aaaaaaaa") has the
    // entropy of a much shorter one.
    if (RegExp(r'^(.)\1+$').hasMatch(password)) bits *= 0.25;

    // Sequential runs (abcdef, 123456, qwerty) are the first thing a cracker
    // tries, so they buy far less than their length suggests.
    if (_hasSequentialRun(password, 4)) bits *= 0.6;

    // Known-common passwords are effectively zero-entropy regardless of shape.
    if (commonPasswords.contains(password.toLowerCase())) {
      return PasswordStrength.veryWeak;
    }

    if (password.length < 8 || bits < 36) return PasswordStrength.veryWeak;
    if (bits < 60) return PasswordStrength.weak;
    if (bits < 80) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  /// True when [password] contains an ascending or descending run of at least
  /// [minRun] characters by code unit, or a run along a keyboard row.
  static bool _hasSequentialRun(String password, int minRun) {
    final lower = password.toLowerCase();

    var ascending = 1;
    var descending = 1;
    for (var i = 1; i < lower.length; i++) {
      final delta = lower.codeUnitAt(i) - lower.codeUnitAt(i - 1);
      ascending = delta == 1 ? ascending + 1 : 1;
      descending = delta == -1 ? descending + 1 : 1;
      if (ascending >= minRun || descending >= minRun) return true;
    }

    for (final row in _keyboardRows) {
      for (var i = 0; i + minRun <= row.length; i++) {
        final slice = row.substring(i, i + minRun);
        if (lower.contains(slice) ||
            lower.contains(slice.split('').reversed.join())) {
          return true;
        }
      }
    }
    return false;
  }

  static const _keyboardRows = [
    'qwertyuiop',
    'asdfghjkl',
    'zxcvbnm',
    '1234567890',
  ];

  /// Offline list of passwords common enough that any match should be treated
  /// as already breached. Deliberately small and local — the optional online
  /// check in `BreachService` covers the long tail.
  static const commonPasswords = <String>{
    '123456', '123456789', '12345678', '12345', '1234567', '1234567890',
    'password', 'password1', 'password123', 'qwerty', 'qwerty123', 'abc123',
    '111111', '000000', '123123', 'iloveyou', 'admin', 'welcome', 'monkey',
    'dragon', 'letmein', 'login', 'princess', 'sunshine', 'master', 'football',
    'baseball', 'shadow', 'superman', 'trustno1', 'passw0rd', 'zaq12wsx',
    'asdfghjkl', 'qazwsx', 'michael', 'jennifer', 'jordan', 'harley',
    'hunter', 'ranger', 'buster', 'batman', 'starwars', 'whatever', 'freedom',
    'ginger', 'summer', 'ashley', 'nicole', 'chelsea', 'matrix', 'secret',
    '1q2w3e4r', '1qaz2wsx', 'qwertyuiop', 'aa123456', 'abcd1234', 'test123',
  };
}
