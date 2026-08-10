import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/api.dart' show InvalidCipherTextException;
import 'package:ramz_save/services/encryption_service.dart';

/// The envelope scheme the whole app rests on. If these break, a user either
/// cannot open their vault or an attacker can.
///
/// The iteration count is lowered wherever a test only needs "some key": at the
/// production 100,000 rounds each derivation costs a noticeable fraction of a
/// second, and a handful of them would turn this file into a slow test.
void main() {
  group('deriveKey', () {
    test('same password and salt derive the same key', () {
      final salt = EncryptionService.generateSalt();

      final a = EncryptionService.deriveKey(
        password: 'رمز-اصلی-من',
        salt: salt,
        rounds: 1000,
      );
      final b = EncryptionService.deriveKey(
        password: 'رمز-اصلی-من',
        salt: salt,
        rounds: 1000,
      );

      expect(a.key, equals(b.key));
      expect(a.key.length, EncryptionService.keyLength);
    });

    test('a different salt derives a different key from the same password', () {
      final a = EncryptionService.deriveKey(password: 'hunter2', rounds: 1000);
      final b = EncryptionService.deriveKey(password: 'hunter2', rounds: 1000);

      // The salt is what stops one rainbow table from opening every vault.
      expect(a.salt, isNot(equals(b.salt)));
      expect(a.key, isNot(equals(b.key)));
    });

    test('the async derivation matches the synchronous one', () async {
      final salt = EncryptionService.generateSalt();

      final sync = EncryptionService.deriveKey(
        password: 'hunter2',
        salt: salt,
        rounds: 1000,
      );
      final async = await EncryptionService.deriveKeyAsync(
        password: 'hunter2',
        salt: salt,
        rounds: 1000,
      );

      // Unlocking runs on an isolate; a mismatch here would mean a vault that
      // opens in a test and refuses the same password in the app.
      expect(async.key, equals(sync.key));
    });
  });

  group('encryptBytes / decryptBytes', () {
    final key = EncryptionService.randomBytes(EncryptionService.keyLength);

    test('round-trips a payload', () {
      final plaintext = Uint8List.fromList(utf8.encode('گاوصندوق رمزها'));

      final sealed = EncryptionService.encryptBytes(key, plaintext);
      final opened = EncryptionService.decryptBytes(key, sealed);

      expect(opened, equals(plaintext));
    });

    test('the same plaintext encrypts differently every time', () {
      final plaintext = Uint8List.fromList(utf8.encode('same input'));

      final first = EncryptionService.encryptBytes(key, plaintext);
      final second = EncryptionService.encryptBytes(key, plaintext);

      // A fresh nonce per call. Without it, two entries sharing a password
      // would be visibly identical on disk.
      expect(first, isNot(equals(second)));
    });

    test('a wrong key is rejected rather than returning garbage', () {
      final sealed = EncryptionService.encryptBytes(
        key,
        Uint8List.fromList(utf8.encode('secret')),
      );
      final wrong = EncryptionService.randomBytes(
        EncryptionService.keyLength,
      );

      expect(
        () => EncryptionService.decryptBytes(wrong, sealed),
        throwsA(isA<InvalidCipherTextException>()),
      );
    });

    test('a tampered ciphertext is rejected', () {
      final sealed = EncryptionService.encryptBytes(
        key,
        Uint8List.fromList(utf8.encode('secret')),
      );

      // Flip a bit past the nonce. GCM's tag covers the ciphertext, so this
      // must fail the same way a wrong key does.
      final tampered = Uint8List.fromList(sealed);
      tampered[EncryptionService.nonceLength] ^= 0x01;

      expect(
        () => EncryptionService.decryptBytes(key, tampered),
        throwsA(isA<InvalidCipherTextException>()),
      );
    });

    test('a truncated payload is rejected instead of read out of range', () {
      final tooShort = EncryptionService.randomBytes(
        EncryptionService.nonceLength,
      );

      expect(
        () => EncryptionService.decryptBytes(key, tooShort),
        throwsA(isA<InvalidCipherTextException>()),
      );
    });
  });

  group('wrapDek / unwrapDek', () {
    test('the right password recovers the exact key', () {
      final dek = EncryptionService.generateDek();
      final derived = EncryptionService.deriveKey(
        password: 'رمز اصلی',
        rounds: 1000,
      );

      final wrapped = EncryptionService.wrapDek(derived.key, dek);
      final unwrapped = EncryptionService.unwrapDek(derived.key, wrapped);

      expect(unwrapped, equals(dek));
    });

    test('a wrong password returns null rather than throwing', () {
      final dek = EncryptionService.generateDek();
      final salt = EncryptionService.generateSalt();

      final right = EncryptionService.deriveKey(
        password: 'correct horse',
        salt: salt,
        rounds: 1000,
      );
      final wrong = EncryptionService.deriveKey(
        password: 'battery staple',
        salt: salt,
        rounds: 1000,
      );

      final wrapped = EncryptionService.wrapDek(right.key, dek);

      // Null, not an exception: this is the wrong-master-password path, and the
      // unlock screen treats it as an answer rather than a crash.
      expect(EncryptionService.unwrapDek(wrong.key, wrapped), isNull);
    });

    test('a corrupt blob returns null', () {
      final kek = EncryptionService.randomBytes(EncryptionService.keyLength);

      expect(EncryptionService.unwrapDek(kek, 'not base64 at all'), isNull);
      expect(EncryptionService.unwrapDek(kek, base64Encode([1, 2, 3])), isNull);
    });

    test('re-wrapping under a new password keeps the same vault key', () {
      // This is what changing the master password does. The DEK must survive
      // untouched, or every stored entry becomes unreadable.
      final dek = EncryptionService.generateDek();

      final old = EncryptionService.deriveKey(password: 'old', rounds: 1000);
      final wrapped = EncryptionService.wrapDek(old.key, dek);

      final recovered = EncryptionService.unwrapDek(old.key, wrapped)!;
      final next = EncryptionService.deriveKey(password: 'new', rounds: 1000);
      final rewrapped = EncryptionService.wrapDek(next.key, recovered);

      expect(EncryptionService.unwrapDek(next.key, rewrapped), equals(dek));
      expect(EncryptionService.unwrapDek(old.key, rewrapped), isNull);
    });
  });

  group('encryptString / decryptString', () {
    test('round-trips Persian text', () {
      final key = EncryptionService.randomBytes(EncryptionService.keyLength);
      const plaintext = 'یادداشت فارسی با ارقام ۱۲۳۴';

      final sealed = EncryptionService.encryptString(key, plaintext);

      expect(EncryptionService.decryptString(key, sealed), plaintext);
    });

    test('a wrong key returns null', () {
      final key = EncryptionService.randomBytes(EncryptionService.keyLength);
      final other = EncryptionService.randomBytes(EncryptionService.keyLength);

      final sealed = EncryptionService.encryptString(key, 'backup payload');

      expect(EncryptionService.decryptString(other, sealed), isNull);
    });
  });

  group('wipe', () {
    test('zeroes the key material in place', () {
      final key = EncryptionService.generateDek();
      expect(key.any((b) => b != 0), isTrue);

      EncryptionService.wipe(key);

      // In place, not a fresh buffer: the point is that the bytes still sitting
      // in the old allocation are gone.
      expect(key.every((b) => b == 0), isTrue);
    });
  });
}
