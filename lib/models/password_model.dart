/// Options for the password generator, mirroring the toggles on its screen.
class PasswordOptions {
  final int length;
  final bool lowercase;
  final bool uppercase;
  final bool digits;
  final bool symbols;
  final bool excludeAmbiguous;

  const PasswordOptions({
    this.length = 16,
    this.lowercase = true,
    this.uppercase = true,
    this.digits = true,
    this.symbols = false,
    this.excludeAmbiguous = false,
  });

  /// Slider bounds, matching the design's 13–25 range but widened at both ends
  /// so short PIN-like and long high-entropy passwords are both reachable.
  static const minLength = 8;
  static const maxLength = 64;

  /// False when every character set is off — generation would have nothing to
  /// draw from, so the UI disables the generate action.
  bool get hasAnyCharSet => lowercase || uppercase || digits || symbols;

  PasswordOptions copyWith({
    int? length,
    bool? lowercase,
    bool? uppercase,
    bool? digits,
    bool? symbols,
    bool? excludeAmbiguous,
  }) {
    return PasswordOptions(
      length: length ?? this.length,
      lowercase: lowercase ?? this.lowercase,
      uppercase: uppercase ?? this.uppercase,
      digits: digits ?? this.digits,
      symbols: symbols ?? this.symbols,
      excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
    );
  }

  Map<String, dynamic> toJson() => {
    'length': length,
    'lowercase': lowercase,
    'uppercase': uppercase,
    'digits': digits,
    'symbols': symbols,
    'excludeAmbiguous': excludeAmbiguous,
  };

  factory PasswordOptions.fromJson(Map<dynamic, dynamic> json) {
    return PasswordOptions(
      length: (json['length'] as num?)?.toInt() ?? 16,
      lowercase: json['lowercase'] as bool? ?? true,
      uppercase: json['uppercase'] as bool? ?? true,
      digits: json['digits'] as bool? ?? true,
      symbols: json['symbols'] as bool? ?? false,
      excludeAmbiguous: json['excludeAmbiguous'] as bool? ?? false,
    );
  }
}
