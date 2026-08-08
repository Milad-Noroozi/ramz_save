import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/password_model.dart';
import '../services/local_db_service.dart';
import '../utils/password_utils.dart';

/// Drives the password generator screen.
///
/// Options are persisted, so the length and character sets a user settled on
/// are still there next time — regenerating a password should not mean
/// re-choosing the rules.
class PasswordGeneratorController extends ChangeNotifier {
  final LocalDbService _db;

  PasswordGeneratorController({required LocalDbService db}) : _db = db;

  PasswordOptions _options = const PasswordOptions();
  PasswordOptions get options => _options;

  String _password = '';
  String get password => _password;

  /// True from a copy until the clipboard is cleared. Lives here rather than in
  /// the view because a `build()`-local flag resets on every frame.
  bool _copied = false;
  bool get copied => _copied;

  Timer? _clipboardTimer;

  PasswordStrength get strength => PasswordUtils.estimate(_password);

  /// Loads saved options and produces a first password, so the screen is never
  /// shown empty.
  void start() {
    if (_db.isOpen) _options = _db.readGeneratorOptions();
    regenerate();
  }

  /// Makes a new password from the current options.
  ///
  /// Silently does nothing when every character set is off; the screen disables
  /// its button in that state and shows [PasswordOptions.hasAnyCharSet]'s
  /// message instead.
  void regenerate() {
    if (!_options.hasAnyCharSet) {
      _password = '';
      notifyListeners();
      return;
    }

    _password = PasswordUtils.generate(
      length: _options.length,
      lowercase: _options.lowercase,
      uppercase: _options.uppercase,
      digits: _options.digits,
      symbols: _options.symbols,
      excludeAmbiguous: _options.excludeAmbiguous,
    );
    _copied = false;
    notifyListeners();
  }

  /// Applies new options, regenerates, and persists.
  ///
  /// Regenerating on every change is deliberate: the password on screen always
  /// matches the switches above it, so what the user copies is what they see.
  void update(PasswordOptions next) {
    _options = next;
    regenerate();
    unawaited(_persist());
  }

  void setLength(int length) =>
      update(_options.copyWith(length: length.clamp(
        PasswordOptions.minLength,
        PasswordOptions.maxLength,
      )));

  void toggleLowercase(bool value) =>
      update(_options.copyWith(lowercase: value));
  void toggleUppercase(bool value) =>
      update(_options.copyWith(uppercase: value));
  void toggleDigits(bool value) => update(_options.copyWith(digits: value));
  void toggleSymbols(bool value) => update(_options.copyWith(symbols: value));
  void toggleExcludeAmbiguous(bool value) =>
      update(_options.copyWith(excludeAmbiguous: value));

  /// Copies to the clipboard and schedules it to be wiped.
  ///
  /// See [clipboardTimeout] for why the wipe matters.
  Future<void> copy() async {
    if (_password.isEmpty) return;
    await copyToClipboard(_password);
    _copied = true;
    notifyListeners();
  }

  /// How long a copied secret is allowed to sit on the clipboard.
  ///
  /// The clipboard is readable by every app on the device and survives the vault
  /// locking, so a copied password outlives the protection around it until this
  /// fires.
  static const clipboardTimeout = Duration(seconds: 30);

  /// Copies [value] and clears it after [clipboardTimeout], but only if it is
  /// still the value on the clipboard — clearing unconditionally would wipe
  /// whatever the user copied in the meantime.
  Future<void> copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));

    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(clipboardTimeout, () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
      _copied = false;
      notifyListeners();
    });
  }

  Future<void> _persist() async {
    if (_db.isOpen) await _db.saveGeneratorOptions(_options);
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    super.dispose();
  }
}
