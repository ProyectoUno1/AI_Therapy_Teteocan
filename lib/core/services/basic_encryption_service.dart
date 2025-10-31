// lib/core/services/basic_encryption_service.dart
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class BasicEncryptionService {
  static final BasicEncryptionService _instance = BasicEncryptionService._internal();
  factory BasicEncryptionService() => _instance;
  BasicEncryptionService._internal();

  // Clave fija para cifrado básico (debería venir de variables de entorno)
  final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final _iv = encrypt.IV.fromLength(16);

  /// Cifra un mensaje con AES
  String encryptMessage(String plainText) {
    try {
      if (plainText.isEmpty) return plainText;
      
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('❌ Error cifrando mensaje: $e');
      return plainText; // Fallback a texto plano
    }
  }

  /// Descifra un mensaje con AES
  String decryptMessage(String encryptedBase64) {
    try {
      if (encryptedBase64.isEmpty) return encryptedBase64;
      
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      final decrypted = encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      print('❌ Error descifrando mensaje: $e');
      // Intentar detectar si es texto plano
      if (!_looksLikeEncrypted(encryptedBase64)) {
        return encryptedBase64;
      }
      return '[Error al descifrar mensaje]';
    }
  }

  /// Verifica si un texto parece estar cifrado
  bool _looksLikeEncrypted(String text) {
    if (text.isEmpty) return false;
    try {
      // Los textos cifrados en base64 suelen tener longitud específica
      base64.decode(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si un texto está cifrado
  bool isEncrypted(String text) {
    return _looksLikeEncrypted(text);
  }
}