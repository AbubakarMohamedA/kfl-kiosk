import 'package:flutter_test/flutter_test.dart';
import 'package:sss/core/utils/encryption_util.dart';

void main() {
  group('EncryptionUtil Tests', () {
    test('Should encrypt and precisely decrypt a string', () {
      const original = "mySecretSapPassword123!@#";
      final encrypted = EncryptionUtil.encryptString(original);
      
      expect(encrypted, isNot(original));
      
      final decrypted = EncryptionUtil.decryptString(encrypted);
      expect(decrypted, original);
    });

    test('Should handle empty strings gracefully', () {
      final encrypted = EncryptionUtil.encryptString('');
      expect(encrypted, '');
      
      final decrypted = EncryptionUtil.decryptString('');
      expect(decrypted, '');
    });

    test('Should fall back to plain text if decryption fails (backwards runtime compat)', () {
      const legacyPlainText = "legacyPassword123";
      // Assuming it's not base-64 or properly encrypted bytes, it will throw an error and return original
      final decrypted = EncryptionUtil.decryptString(legacyPlainText);
      expect(decrypted, legacyPlainText);
    });
  });
}
