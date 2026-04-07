import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class EncryptionUtil {
  // We use a fixed 32-byte key for AES encryption of configuration passwords.
  // In a production system, this could be fetched from environment variables.
  static final _key = encrypt.Key.fromUtf8('3f8b9e1c4d2a705e6b1f204c8a9d3e5f');
  static final _iv = encrypt.IV.fromUtf8('e1c4d2a705e6b1f2'); // 16 bytes IV

  static String encryptString(String plainText) {
    if (plainText.isEmpty) return plainText;
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('EncryptionUtil: Error encrypting string: \$e');
      return plainText;
    }
  }

  static String decryptString(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      // If decryption fails, it might be an older legacy plain-text password.
      // So we return it intact to preserve backwards compatibility.
      return encryptedText;
    }
  }
}
