// lib/services/e2ee_service.dart


import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:asn1lib/asn1lib.dart';

class E2EEService {
  static final E2EEService _instance = E2EEService._internal();
  factory E2EEService() => _instance;
  E2EEService._internal();

  final _storage = const FlutterSecureStorage();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Claves del usuario actual
  RSAPublicKey? _publicKey;
  RSAPrivateKey? _privateKey;
  
  // Cache de claves públicas de otros usuarios
  final Map<String, RSAPublicKey> _publicKeyCache = {};

  /// Inicializa el servicio E2EE al iniciar sesión
  Future<void> initialize() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Intentar cargar claves existentes
      final hasKeys = await _loadKeysFromStorage();
    } catch (e) {
      rethrow;
    }
  }

  /// Genera un nuevo par de claves RSA y las almacena
  Future<void> generateAndStoreKeys() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Generar par de claves RSA-2048
      final keyPair = _generateRSAKeyPair();
      _publicKey = keyPair.publicKey as RSAPublicKey;
      _privateKey = keyPair.privateKey as RSAPrivateKey;

      // Guardar clave privada en almacenamiento seguro
      await _savePrivateKeyToStorage(_privateKey!);

      // Guardar clave pública en Firestore
      await _savePublicKeyToFirestore(userId, _publicKey!);
    } catch (e) {
      rethrow;
    }
  }

  /// Genera un par de claves RSA-2048
  crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey> _generateRSAKeyPair() {
    final keyGen = RSAKeyGenerator()
      ..init(
        crypto.ParametersWithRandom(
          RSAKeyGeneratorParameters(
            BigInt.parse('65537'),
            2048,
            64,
          ),
          _getSecureRandom(),
        ),
      );

    return keyGen.generateKeyPair();
  }

  /// Genera números aleatorios seguros
  crypto.SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(crypto.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Convierte RSAPrivateKey a PEM
  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final topLevel = ASN1Sequence();
    
    topLevel.add(ASN1Integer(BigInt.from(0)));
    topLevel.add(ASN1Integer(privateKey.modulus!));
    topLevel.add(ASN1Integer(privateKey.publicExponent!));
    topLevel.add(ASN1Integer(privateKey.privateExponent!));
    topLevel.add(ASN1Integer(privateKey.p!));
    topLevel.add(ASN1Integer(privateKey.q!));
    
    final dataBase64 = base64.encode(topLevel.encodedBytes);
    final chunks = <String>[];
    
    for (var i = 0; i < dataBase64.length; i += 64) {
      final end = (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length;
      chunks.add(dataBase64.substring(i, end));
    }
    
    return '-----BEGIN RSA PRIVATE KEY-----\n${chunks.join('\n')}\n-----END RSA PRIVATE KEY-----';
  }

  /// Convierte RSAPublicKey a PEM
  String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    final topLevel = ASN1Sequence();
    
    topLevel.add(ASN1Integer(publicKey.modulus!));
    topLevel.add(ASN1Integer(publicKey.exponent!));
    
    final dataBase64 = base64.encode(topLevel.encodedBytes);
    final chunks = <String>[];
    
    for (var i = 0; i < dataBase64.length; i += 64) {
      final end = (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length;
      chunks.add(dataBase64.substring(i, end));
    }
    
    return '-----BEGIN RSA PUBLIC KEY-----\n${chunks.join('\n')}\n-----END RSA PUBLIC KEY-----';
  }

  /// Parsea PEM a RSAPrivateKey
  RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
    final rows = pem.split('\n').where((row) {
      return !row.startsWith('-----');
    }).join('');
    
    final keyBytes = base64.decode(rows);
    final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    
    final modulus = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
    final privateExponent = (topLevelSeq.elements[3] as ASN1Integer).valueAsBigInteger;
    final p = (topLevelSeq.elements[4] as ASN1Integer).valueAsBigInteger;
    final q = (topLevelSeq.elements[5] as ASN1Integer).valueAsBigInteger;
    
    return RSAPrivateKey(modulus, privateExponent, p, q);
  }

  /// Parsea PEM a RSAPublicKey
  RSAPublicKey _parsePublicKeyFromPem(String pem) {
    final rows = pem.split('\n').where((row) {
      return !row.startsWith('-----');
    }).join('');
    
    final keyBytes = base64.decode(rows);
    final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    
    final modulus = (topLevelSeq.elements[0] as ASN1Integer).valueAsBigInteger;
    final exponent = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
    
    return RSAPublicKey(modulus, exponent);
  }

  /// Guarda la clave privada en almacenamiento seguro
  Future<void> _savePrivateKeyToStorage(RSAPrivateKey privateKey) async {
    final pemString = _encodePrivateKeyToPem(privateKey);
    await _storage.write(key: 'rsa_private_key', value: pemString);
  }

  /// Guarda la clave pública en Firestore
  Future<void> _savePublicKeyToFirestore(String userId, RSAPublicKey publicKey) async {
    final pemString = _encodePublicKeyToPem(publicKey);
    
    await _firestore.collection('users').doc(userId).set({
      'publicKey': pemString,
      'keyGeneratedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Carga las claves desde almacenamiento seguro
  Future<bool> _loadKeysFromStorage() async {
    try {
      final privatePem = await _storage.read(key: 'rsa_private_key');
      if (privatePem == null) return false;

      _privateKey = _parsePrivateKeyFromPem(privatePem);

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data()?['publicKey'] == null) {
        return false;
      }

      _publicKey = _parsePublicKeyFromPem(userDoc.data()!['publicKey']);
      return true;
    } catch (e) {
      print('Error cargando claves: $e');
      return false;
    }
  }

  /// Obtiene la clave pública de otro usuario desde Firestore
  Future<RSAPublicKey> _getPublicKey(String userId) async {
    if (_publicKeyCache.containsKey(userId)) {
      return _publicKeyCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists || userDoc.data()?['publicKey'] == null) {
        throw Exception('Clave pública no encontrada para usuario $userId');
      }

      final publicKey = _parsePublicKeyFromPem(userDoc.data()!['publicKey']);
      _publicKeyCache[userId] = publicKey;
      
      return publicKey;
    } catch (e) {
      print('Error obteniendo clave pública: $e');
      rethrow;
    }
  }

  /// Cifra un mensaje para un destinatario específico (Chat humano)
  Future<String> encryptMessage(String plainText, String recipientUserId) async {
    try {
      final recipientPublicKey = await _getPublicKey(recipientUserId);

      final aesKey = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );
      final encryptedMessage = encrypter.encrypt(plainText, iv: iv);

      final rsaEncrypter = encrypt.Encrypter(
        encrypt.RSA(publicKey: recipientPublicKey),
      );
      final encryptedKey = rsaEncrypter.encryptBytes(aesKey.bytes);

      final payload = {
        'encryptedMessage': encryptedMessage.base64,
        'encryptedKey': encryptedKey.base64,
        'iv': iv.base64,
        'version': '1.0',
      };

      return jsonEncode(payload);
    } catch (e) {
      print('Error cifrando mensaje: $e');
      rethrow;
    }
  }

  /// Descifra un mensaje recibido (Chat humano)
  Future<String> decryptMessage(String encryptedPayload) async {
    try {
      if (_privateKey == null) {
        throw Exception('Clave privada no disponible');
      }

      final payload = jsonDecode(encryptedPayload) as Map<String, dynamic>;

      final rsaEncrypter = encrypt.Encrypter(
        encrypt.RSA(privateKey: _privateKey),
      );
      final encryptedKey = encrypt.Encrypted.fromBase64(payload['encryptedKey']);
      final aesKeyBytes = rsaEncrypter.decryptBytes(encryptedKey);
      final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));

      final iv = encrypt.IV.fromBase64(payload['iv']);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );
      final encryptedMessage = encrypt.Encrypted.fromBase64(payload['encryptedMessage']);
      
      return encrypter.decrypt(encryptedMessage, iv: iv);
    } catch (e) {
      print('Error descifrando mensaje: $e');
      return '[Mensaje cifrado - No se puede descifrar]';
    }
  }

  /// Cifra mensaje para Aurora AI (solo con clave del usuario)
  Future<String> encryptForAI(String plainText) async {
    try {
      if (_publicKey == null) {
        throw Exception('Clave pública no disponible');
      }

      final aesKey = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );
      final encryptedMessage = encrypter.encrypt(plainText, iv: iv);

      final rsaEncrypter = encrypt.Encrypter(
        encrypt.RSA(publicKey: _publicKey),
      );
      final encryptedKey = rsaEncrypter.encryptBytes(aesKey.bytes);

      final payload = {
        'encryptedMessage': encryptedMessage.base64,
        'encryptedKey': encryptedKey.base64,
        'iv': iv.base64,
        'type': 'ai_chat',
        'version': '1.0',
      };

      return jsonEncode(payload);
    } catch (e) {
      print('Error cifrando para IA: $e');
      rethrow;
    }
  }

  /// Descifra mensaje de Aurora AI
  Future<String> decryptFromAI(String encryptedPayload) async {
    return decryptMessage(encryptedPayload);
  }

  /// Verifica si el usuario tiene claves configuradas
  Future<bool> hasKeys() async {
    final privatePem = await _storage.read(key: 'rsa_private_key');
    return privatePem != null && _privateKey != null;
  }

  /// Regenera claves (útil si se corrompen)
  Future<void> regenerateKeys() async {
    await _storage.delete(key: 'rsa_private_key');
    _publicKey = null;
    _privateKey = null;
    _publicKeyCache.clear();
    await generateAndStoreKeys();
  }

  /// Limpia las claves al cerrar sesión
  Future<void> clearKeys() async {
    await _storage.delete(key: 'rsa_private_key');
    _publicKey = null;
    _privateKey = null;
    _publicKeyCache.clear();
    print('🗑️ Claves eliminadas del dispositivo');
  }
}