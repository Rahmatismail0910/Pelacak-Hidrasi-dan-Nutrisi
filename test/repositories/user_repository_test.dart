import 'package:flutter_test/flutter_test.dart';
import 'package:pelacak_hidrasi_dan_nutrisi/services/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('password yang benar menghasilkan verifikasi berhasil', () async {
      const password = 'PasswordUji123!';
      final hash = await PasswordHasher.hash(password);

      expect(await PasswordHasher.verify(password, hash), isTrue);
    });

    test('password yang salah ditolak', () async {
      final hash = await PasswordHasher.hash('PasswordUji123!');

      expect(await PasswordHasher.verify('PasswordSalah123!', hash), isFalse);
    });

    test('salt yang berbeda menghasilkan hash berbeda', () async {
      final first = await PasswordHasher.hash('PasswordUji123!');
      final second = await PasswordHasher.hash('PasswordUji123!');

      expect(first, isNot(second));
    });
  });
}
