import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../utils/password_utils.dart';

/// Checks whether a password is known to be compromised.
///
/// Two tiers, and the offline one is the default:
///
/// * **Offline** — membership in a bundled list of the most common passwords.
///   Instant, private, and catches the passwords that actually get guessed.
/// * **Online** — Have I Been Pwned's range API, opt-in through Settings. It
///   covers billions of leaked credentials, which no bundled list can.
///
/// The online path uses k-anonymity: only the first five hex characters of the
/// password's SHA-1 are sent. The server returns every suffix sharing that
/// prefix — several hundred of them — and the match is decided here. HIBP never
/// learns the password, its full hash, or which of the returned rows was ours.
///
/// SHA-1 is used because it is the protocol's hash, not a security choice; the
/// value is a lookup key, never a stored credential.
class BreachService {
  static const _host = 'api.pwnedpasswords.com';
  static const _timeout = Duration(seconds: 8);

  final HttpClient Function() _clientFactory;

  BreachService({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  /// Offline check: is this one of the passwords everybody uses?
  bool isCommon(String password) =>
      PasswordUtils.commonPasswords.contains(password.toLowerCase());

  /// How many breaches this password appears in, or `null` when the check could
  /// not be completed (offline, timeout, server error).
  ///
  /// `null` and `0` mean different things and must not be collapsed: `0` is
  /// evidence of safety, `null` is absence of evidence. Callers should leave an
  /// entry's status unchanged on `null` rather than marking it safe.
  Future<int?> breachCount(String password) async {
    final digest = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = digest.substring(0, 5);
    final suffix = digest.substring(5);

    final client = _clientFactory()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(
        Uri.https(_host, '/range/$prefix'),
      );
      // Required by HIBP, and it also pads the response with fake rows so the
      // reply size doesn't hint at how many real matches the prefix has.
      request.headers.set('Add-Padding', 'true');
      request.headers.set(HttpHeaders.userAgentHeader, 'RamzSave');

      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) return null;

      final body = await response.transform(utf8.decoder).join();
      return countFor(suffix, body);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Finds [suffix] in a range response, whose rows are `SUFFIX:COUNT`.
  ///
  /// Split out from the request so the parsing is testable without a network,
  /// and so a malformed row can't take down the whole check.
  int countFor(String suffix, String responseBody) {
    for (final line in const LineSplitter().convert(responseBody)) {
      final separator = line.indexOf(':');
      if (separator == -1) continue;
      if (line.substring(0, separator).trim().toUpperCase() != suffix) continue;

      // Padding rows are real suffixes with a count of 0; parsing them as 0 is
      // the correct outcome anyway.
      return int.tryParse(line.substring(separator + 1).trim()) ?? 0;
    }
    return 0;
  }

  /// The combined verdict for one password.
  ///
  /// [online] is what the settings toggle controls. When it is off — or when
  /// the request fails — this degrades to the offline answer rather than
  /// reporting "safe" on no information.
  Future<bool> isCompromised(String password, {bool online = false}) async {
    if (isCommon(password)) return true;
    if (!online) return false;
    final count = await breachCount(password);
    return count != null && count > 0;
  }
}
