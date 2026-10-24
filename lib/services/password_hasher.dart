import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class PasswordHasher {
  static final Pbkdf2 _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  static Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));

    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final hashBytes = await key.extractBytes();

    return '${base64Encode(salt)}:${base64Encode(hashBytes)}';
  }

  static Future<bool> verify(String password, String storedHash) async {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;

      final salt = base64Decode(parts[0]);
      final expectedHash = base64Decode(parts[1]);

      if (salt.length != 16 || expectedHash.length != 32) {
        return false;
      }

      final key = await _algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final actualHash = await key.extractBytes();

      return constantTimeEquals(actualHash, expectedHash);
    } catch (_) {
      return false;
    }
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;

    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }
}
