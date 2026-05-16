import 'package:encrypt/encrypt.dart';

class SecurityService {
  // AES-256 requires a 32-character key
  static final _key = Key.fromUtf8('QubicoTransportes2024SecureKey!!'); 
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key));

  /// Encrypts a string using AES-256
  static String encrypt(String text) {
    if (text.isEmpty) return text;
    final encrypted = _encrypter.encrypt(text, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a base64 string using AES-256
  static String decrypt(String base64Text) {
    if (base64Text.isEmpty) return base64Text;
    try {
      return _encrypter.decrypt64(base64Text, iv: _iv);
    } catch (e) {
      // If decryption fails (e.g. it wasn't encrypted), return original
      return base64Text;
    }
  }
}
