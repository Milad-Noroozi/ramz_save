import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// A key-encryption key derived from the master password, kept with the salt
/// and iteration count that produced it so it can be re-derived or upgraded.
class DerivedKey {
  final Uint8List key;
  final Uint8List salt;
  final int iterations;

  const DerivedKey({
    required this.key,
    required this.salt,
    required this.iterations,
  });
}

/// Low-level crypto primitives. Holds no state and touches no storage — see
/// `SecureStorageService` for where the outputs are persisted.
///
/// The design is envelope encryption:
///
/// ```
/// master password ──PBKDF2──> KEK ──AES-GCM──> wrapped DEK ──> keystore
///                                                   │
///                        DEK (random 32 bytes) ─────┘
///                          └──> HiveAesCipher ──> encrypted box on disk
/// ```
///
/// Changing the master password only re-wraps the DEK, so the vault itself is
/// never re-encrypted; and biometric unlock can release the DEK without the
/// master password ever being stored.
class EncryptionService {
  EncryptionService._();

  /// OWASP's floor for PBKDF2-HMAC-SHA256. Stored alongside each derivation so
  /// old vaults keep opening if this is raised later.
  static const iterations = 100000;

  static const keyLength = 32; // AES-256
  static const saltLength = 16;
  static const nonceLength = 12; // GCM standard
  static const macLength = 16;

  static final Random _random = Random.secure();

  static Uint8List randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// Fresh 256-bit data-encryption key. This is what actually encrypts the
  /// vault; it never leaves the device unwrapped.
  static Uint8List generateDek() => randomBytes(keyLength);

  static Uint8List generateSalt() => randomBytes(saltLength);

  /// Stretches [password] into a KEK. Intentionally slow — the iteration count
  /// is the only thing standing between a stolen device and an offline
  /// brute-force of the master password.
  static DerivedKey deriveKey({
    required String password,
    Uint8List? salt,
    int rounds = iterations,
  }) {
    final effectiveSalt = salt ?? generateSalt();
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(effectiveSalt, rounds, keyLength));

    final key = derivator.process(
      Uint8List.fromList(utf8.encode(password)),
    );

    return DerivedKey(key: key, salt: effectiveSalt, iterations: rounds);
  }

  /// AES-256-GCM. Returns `nonce || ciphertext || tag` as one buffer, so
  /// callers never have to keep the three pieces in step.
  static Uint8List encryptBytes(Uint8List key, Uint8List plaintext) {
    final nonce = randomBytes(nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          macLength * 8,
          nonce,
          Uint8List(0),
        ),
      );

    final sealed = cipher.process(plaintext);
    return Uint8List.fromList([...nonce, ...sealed]);
  }

  /// Inverse of [encryptBytes].
  ///
  /// Throws [InvalidCipherTextException] when the tag does not verify — which
  /// is exactly what a wrong key looks like, and is how wrong-password
  /// detection is implemented upstream.
  static Uint8List decryptBytes(Uint8List key, Uint8List payload) {
    if (payload.length < nonceLength + macLength) {
      throw InvalidCipherTextException('payload too short');
    }

    final nonce = payload.sublist(0, nonceLength);
    final sealed = payload.sublist(nonceLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          macLength * 8,
          nonce,
          Uint8List(0),
        ),
      );

    return cipher.process(sealed);
  }

  /// Wraps the DEK under the KEK for storage in the keystore.
  static String wrapDek(Uint8List kek, Uint8List dek) =>
      base64Encode(encryptBytes(kek, dek));

  /// Unwraps a DEK produced by [wrapDek]. Returns `null` when [kek] is wrong or
  /// the blob is corrupt, so callers can treat both as "bad password" without
  /// catching crypto exceptions themselves.
  static Uint8List? unwrapDek(Uint8List kek, String wrapped) {
    try {
      return decryptBytes(kek, base64Decode(wrapped));
    } catch (_) {
      return null;
    }
  }

  /// Encrypts a UTF-8 string to base64 — used for backup payloads.
  static String encryptString(Uint8List key, String plaintext) =>
      base64Encode(encryptBytes(key, Uint8List.fromList(utf8.encode(plaintext))));

  /// Inverse of [encryptString]; `null` on a wrong key or corrupt input.
  static String? decryptString(Uint8List key, String payload) {
    try {
      return utf8.decode(decryptBytes(key, base64Decode(payload)));
    } catch (_) {
      return null;
    }
  }

  /// Overwrites key material in place.
  ///
  /// Best-effort only: Dart may have copied the buffer during GC, so this
  /// narrows the window in which a key sits in memory rather than closing it.
  static void wipe(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
