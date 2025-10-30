// lib/core/services/e2ee_service.dart
// ✅ VERSIÓN CON DEBUG MEJORADO

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

  RSAPublicKey? _publicKey;
  RSAPrivateKey? _privateKey;
  
  final Map<String, RSAPublicKey> _publicKeyCache = {};

  /// Inicializa el servicio E2EE al iniciar sesión
  Future<void> initialize() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      print('🔑 Inicializando E2EE para usuario: $userId');

      final hasKeys = await _loadKeysFromStorage();
      
      if (!hasKeys) {
        print('⚠️ No se encontraron claves, generando nuevas...');
        await generateAndStoreKeys();
      } else {
        print('✅ Claves cargadas desde almacenamiento');
        print('   - Modulus length: ${_privateKey?.modulus?.bitLength ?? 0} bits');
      }
    } catch (e) {
      print('❌ Error inicializando E2EE: $e');
      try {
        await regenerateKeys();
      } catch (regenerateError) {
        print('❌ Error regenerando claves: $regenerateError');
        rethrow;
      }
    }
  }

  /// Genera un nuevo par de claves RSA y las almacena
  Future<void> generateAndStoreKeys() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      print('🔐 Generando nuevo par de claves RSA-2048...');
      
      final keyPair = _generateRSAKeyPair();
      _publicKey = keyPair.publicKey as RSAPublicKey;
      _privateKey = keyPair.privateKey as RSAPrivateKey;

      print('✅ Claves generadas');
      print('   - Public key modulus: ${_publicKey!.modulus?.bitLength} bits');
      print('   - Private key modulus: ${_privateKey!.modulus?.bitLength} bits');

      await _savePrivateKeyToStorage(_privateKey!);
      await _savePublicKeyToFirestore(userId, _publicKey!);
      
      print('✅ Claves almacenadas correctamente');
    } catch (e) {
      print('❌ Error generando claves: $e');
      rethrow;
    }
  }

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

  crypto.SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(crypto.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final topLevel = ASN1Sequence();
    
    final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
    final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
    final qInv = privateKey.q!.modInverse(privateKey.p!);
    
    topLevel.add(ASN1Integer(BigInt.from(0)));                    
    topLevel.add(ASN1Integer(privateKey.modulus!));               
    topLevel.add(ASN1Integer(privateKey.publicExponent!));        
    topLevel.add(ASN1Integer(privateKey.privateExponent!));      
    topLevel.add(ASN1Integer(privateKey.p!));                    
    topLevel.add(ASN1Integer(privateKey.q!));                     
    topLevel.add(ASN1Integer(dP));                                
    topLevel.add(ASN1Integer(dQ));                                
    topLevel.add(ASN1Integer(qInv));                             
    
    final dataBase64 = base64.encode(topLevel.encodedBytes);
    final chunks = <String>[];
    
    for (var i = 0; i < dataBase64.length; i += 64) {
      final end = (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length;
      chunks.add(dataBase64.substring(i, end));
    }
    
    return '-----BEGIN RSA PRIVATE KEY-----\n${chunks.join('\n')}\n-----END RSA PRIVATE KEY-----';
  }

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

  RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
    try {
      final rows = pem
          .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
          .replaceAll('-----END RSA PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      
      final keyBytes = base64.decode(rows);
      
      final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      
      if (topLevelSeq.elements.length != 9) {
        throw Exception('Formato de clave privada inválido. Elementos: ${topLevelSeq.elements.length}');
      }
      
      final modulus = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
      final publicExponent = (topLevelSeq.elements[2] as ASN1Integer).valueAsBigInteger;
      final privateExponent = (topLevelSeq.elements[3] as ASN1Integer).valueAsBigInteger;
      final p = (topLevelSeq.elements[4] as ASN1Integer).valueAsBigInteger;
      final q = (topLevelSeq.elements[5] as ASN1Integer).valueAsBigInteger;
      
      return RSAPrivateKey(modulus, privateExponent, p, q);
    } catch (e) {
      print('❌ Error parseando clave privada: $e');
      rethrow;
    }
  }

  RSAPublicKey _parsePublicKeyFromPem(String pem) {
    try {
      final rows = pem
          .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
          .replaceAll('-----END RSA PUBLIC KEY-----', '')
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      
      final keyBytes = base64.decode(rows);
      
      final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
      
      try {
        final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
        
        if (topLevelSeq.elements.length == 2) {
          final modulus = (topLevelSeq.elements[0] as ASN1Integer).valueAsBigInteger;
          final exponent = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
          
          return RSAPublicKey(modulus, exponent);
        } else if (topLevelSeq.elements.length > 2) {
          final bitString = topLevelSeq.elements[1] as ASN1BitString;
          final keyParser = ASN1Parser(bitString.valueBytes());
          final keySeq = keyParser.nextObject() as ASN1Sequence;
          
          final modulus = (keySeq.elements[0] as ASN1Integer).valueAsBigInteger;
          final exponent = (keySeq.elements[1] as ASN1Integer).valueAsBigInteger;
          return RSAPublicKey(modulus, exponent);
        }
      } catch (e) {
        rethrow;
      }
      
      throw Exception('Formato de clave pública no reconocido');
    } catch (e) {
      print('❌ Error parseando clave pública: $e');
      rethrow;
    }
  }

  Future<void> _savePrivateKeyToStorage(RSAPrivateKey privateKey) async {
    final pemString = _encodePrivateKeyToPem(privateKey);
    await _storage.write(key: 'rsa_private_key', value: pemString);
    print('💾 Clave privada guardada en almacenamiento seguro');
  }

  Future<void> _savePublicKeyToFirestore(String userId, RSAPublicKey publicKey) async {
    final pemString = _encodePublicKeyToPem(publicKey);
    
    await _firestore.collection('users').doc(userId).set({
      'publicKey': pemString,
      'keyGeneratedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    print('☁️ Clave pública guardada en Firestore para usuario: $userId');
  }

  Future<bool> _loadKeysFromStorage() async {
    try {
      final privatePem = await _storage.read(key: 'rsa_private_key');
      if (privatePem == null) {
        print('⚠️ No se encontró clave privada en almacenamiento');
        return false;
      }

      _privateKey = _parsePrivateKeyFromPem(privatePem);
      print('✅ Clave privada cargada desde almacenamiento');

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data()?['publicKey'] == null) {
        print('⚠️ No se encontró clave pública en Firestore');
        return false;
      }

      _publicKey = _parsePublicKeyFromPem(userDoc.data()!['publicKey']);
      print('✅ Clave pública cargada desde Firestore');
      
      return true;
    } catch (e) {
      print('❌ Error cargando claves: $e');
      return false; 
    }
  }

  Future<RSAPublicKey> _getPublicKey(String userId) async {
    if (_publicKeyCache.containsKey(userId)) {
      print('📦 Usando clave pública del caché para: $userId');
      return _publicKeyCache[userId]!;
    }

    try {
      print('🔍 Obteniendo clave pública de Firestore para: $userId');
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists || userDoc.data()?['publicKey'] == null) {
        throw Exception('❌ Clave pública no encontrada para usuario $userId');
      }

      final publicKey = _parsePublicKeyFromPem(userDoc.data()!['publicKey']);
      _publicKeyCache[userId] = publicKey;
      
      print('✅ Clave pública obtenida: ${publicKey.modulus?.bitLength} bits');
      
      return publicKey;
    } catch (e) {
      print('❌ Error obteniendo clave pública: $e');
      rethrow;
    }
  }

  /// Cifra un mensaje para un destinatario específico (Chat humano)
  Future<String> encryptMessage(String plainText, String recipientUserId) async {
    try {
      print('🔐 Cifrando mensaje para: $recipientUserId');
      
      final recipientPublicKey = await _getPublicKey(recipientUserId);
      
      final aesKey = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );
      final encryptedMessage = encrypter.encrypt(plainText, iv: iv);

      final rsaEncrypter = encrypt.Encrypter(
        encrypt.RSA(
          publicKey: recipientPublicKey,
          encoding: encrypt.RSAEncoding.PKCS1,
        ),
      );
      final encryptedKey = rsaEncrypter.encryptBytes(aesKey.bytes);

      final payload = {
        'encryptedMessage': encryptedMessage.base64,
        'encryptedKey': encryptedKey.base64,
        'iv': iv.base64,
        'version': '1.0',
        'senderKeyModulus': _publicKey!.modulus!.bitLength, // ✅ Debug info
      };
      
      print('✅ Mensaje cifrado correctamente');
      
      return jsonEncode(payload);
    } catch (e) {
      print('❌ Error cifrando mensaje: $e');
      rethrow;
    }
  }

  /// Descifra un mensaje recibido (Chat humano)
  Future<String> decryptMessage(String encryptedPayload) async {
    try {
      if (_privateKey == null) {
        throw Exception('❌ Clave privada no disponible');
      }
      
      print('🔓 Intentando descifrar mensaje...');
      
      final payload = jsonDecode(encryptedPayload) as Map<String, dynamic>;
      
      // ✅ Verificar si tiene los campos necesarios
      if (!payload.containsKey('encryptedMessage') || 
          !payload.containsKey('encryptedKey') || 
          !payload.containsKey('iv')) {
        throw Exception('❌ Payload de mensaje incompleto');
      }

      print('   - Payload version: ${payload['version']}');
      print('   - Sender key modulus: ${payload['senderKeyModulus']} bits');
      print('   - Mi clave privada: ${_privateKey!.modulus?.bitLength} bits');

      final rsaEncrypter = encrypt.Encrypter(
        encrypt.RSA(
          privateKey: _privateKey,
          encoding: encrypt.RSAEncoding.PKCS1,
        ),
      );
      
      final encryptedKey = encrypt.Encrypted.fromBase64(payload['encryptedKey']);
      
      print('   - Descifrando clave AES con RSA...');
      final aesKeyBytes = rsaEncrypter.decryptBytes(encryptedKey);
      print('   ✅ Clave AES descifrada');
      
      final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));

      final iv = encrypt.IV.fromBase64(payload['iv']);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
      );
      final encryptedMessage = encrypt.Encrypted.fromBase64(payload['encryptedMessage']);
      
      print('   - Descifrando mensaje con AES...');
      final decrypted = encrypter.decrypt(encryptedMessage, iv: iv);
      
      print('✅ Mensaje descifrado: ${decrypted.substring(0, decrypted.length > 30 ? 30 : decrypted.length)}...');
      
      return decrypted;
    } catch (e) {
      print('❌ Error descifrando mensaje: $e');
      
      // Mensajes de error más específicos
      if (e.toString().contains('Unsupported block type')) {
        return '🔒 [Mensaje cifrado con clave diferente - No disponible]';
      } else if (e.toString().contains('Bad decrypt')) {
        return '🔒 [Mensaje cifrado con clave anterior]';
      }
      
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
        encrypt.RSA(
          publicKey: _publicKey,
          encoding: encrypt.RSAEncoding.PKCS1,
        ),
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
      print('❌ Error cifrando para IA: $e');
      rethrow;
    }
  }

  Future<String> decryptFromAI(String encryptedPayload) async {
    return decryptMessage(encryptedPayload);
  }

  Future<bool> hasKeys() async {
    final privatePem = await _storage.read(key: 'rsa_private_key');
    return privatePem != null && _privateKey != null;
  }

  Future<void> regenerateKeys() async {
    print('🔄 Regenerando claves E2EE...');
    await _storage.delete(key: 'rsa_private_key');
    _publicKey = null;
    _privateKey = null;
    _publicKeyCache.clear();
    await generateAndStoreKeys();
    print('✅ Claves regeneradas correctamente');
  }

  Future<void> clearKeys() async {
    await _storage.delete(key: 'rsa_private_key');
    _publicKey = null;
    _privateKey = null;
    _publicKeyCache.clear();
  }
}