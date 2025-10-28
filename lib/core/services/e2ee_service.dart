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

      print('🔐 Inicializando E2EE para usuario: $userId');

      // Intentar cargar claves existentes
      final hasKeys = await _loadKeysFromStorage();
      
      // Si no hay claves o falló la carga, generar nuevas
      if (!hasKeys) {
        print('🔄 Generando nuevas claves...');
        await generateAndStoreKeys();
      }
      
      print('✅ E2EE inicializado correctamente');
    } catch (e) {
      // Si hay error inicializando, intentar regenerar claves
      print('⚠️ Error inicializando E2EE, regenerando claves: $e');
      try {
        await regenerateKeys();
        print('✅ Claves regeneradas exitosamente');
      } catch (regenerateError) {
        print('❌ Error crítico regenerando claves: $regenerateError');
        rethrow;
      }
    }
  }

  /// Genera un nuevo par de claves RSA y las almacena
  Future<void> generateAndStoreKeys() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      print('🔧 Generando par de claves RSA-2048...');

      // Generar par de claves RSA-2048
      final keyPair = _generateRSAKeyPair();
      _publicKey = keyPair.publicKey as RSAPublicKey;
      _privateKey = keyPair.privateKey as RSAPrivateKey;

      // Guardar clave privada en almacenamiento seguro
      await _savePrivateKeyToStorage(_privateKey!);

      // Guardar clave pública en Firestore
      await _savePublicKeyToFirestore(userId, _publicKey!);
      
      print('✅ Claves generadas y guardadas exitosamente');
    } catch (e) {
      print('❌ Error generando claves: $e');
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

  /// Convierte RSAPrivateKey a PEM (PKCS#1 con 9 elementos)
  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final topLevel = ASN1Sequence();
    
    // Calcular los valores faltantes para PKCS#1
    final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
    final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
    final qInv = privateKey.q!.modInverse(privateKey.p!);
    
    // PKCS#1 RSAPrivateKey format - 9 elementos requeridos
    topLevel.add(ASN1Integer(BigInt.from(0)));                    // 0: version
    topLevel.add(ASN1Integer(privateKey.modulus!));               // 1: modulus (n)
    topLevel.add(ASN1Integer(privateKey.publicExponent!));        // 2: publicExponent (e)
    topLevel.add(ASN1Integer(privateKey.privateExponent!));       // 3: privateExponent (d)
    topLevel.add(ASN1Integer(privateKey.p!));                     // 4: prime1 (p)
    topLevel.add(ASN1Integer(privateKey.q!));                     // 5: prime2 (q)
    topLevel.add(ASN1Integer(dP));                                // 6: exponent1 (d mod (p-1))
    topLevel.add(ASN1Integer(dQ));                                // 7: exponent2 (d mod (q-1))
    topLevel.add(ASN1Integer(qInv));                              // 8: coefficient ((q^-1) mod p)
    
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
    try {
      print('🔑 Parseando clave privada desde PEM...');
      
      // Eliminar headers y footers
      final rows = pem
          .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
          .replaceAll('-----END RSA PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      
      print('📝 PEM limpio (primeros 50 chars): ${rows.substring(0, rows.length > 50 ? 50 : rows.length)}');
      
      final keyBytes = base64.decode(rows);
      print('📦 Bytes decodificados: ${keyBytes.length}');
      
      final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      
      print('🔍 Elementos en secuencia ASN1: ${topLevelSeq.elements.length}');
      
      // Verificar que sea formato PKCS#1 (debe tener 9 elementos)
      if (topLevelSeq.elements.length != 9) {
        throw Exception('Formato de clave privada inválido. Elementos: ${topLevelSeq.elements.length} (se requieren 9)');
      }
      
      // PKCS#1 RSAPrivateKey format:
      // 0: version
      // 1: modulus (n)
      // 2: publicExponent (e)
      // 3: privateExponent (d)
      // 4: prime1 (p)
      // 5: prime2 (q)
      // 6: exponent1 (d mod (p-1))
      // 7: exponent2 (d mod (q-1))
      // 8: coefficient ((inverse of q) mod p)
      
      final version = (topLevelSeq.elements[0] as ASN1Integer).intValue;
      final modulus = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
      final publicExponent = (topLevelSeq.elements[2] as ASN1Integer).valueAsBigInteger;
      final privateExponent = (topLevelSeq.elements[3] as ASN1Integer).valueAsBigInteger;
      final p = (topLevelSeq.elements[4] as ASN1Integer).valueAsBigInteger;
      final q = (topLevelSeq.elements[5] as ASN1Integer).valueAsBigInteger;
      
      print('✅ Version: $version');
      print('✅ Modulus bits: ${modulus?.bitLength ?? 0}');
      print('✅ Private exponent bits: ${privateExponent?.bitLength ?? 0}');
      
      final privateKey = RSAPrivateKey(modulus, privateExponent, p, q);
      print('✅ Clave privada parseada exitosamente');
      
      return privateKey;
    } catch (e, stackTrace) {
      print('❌ Error parseando clave privada: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  RSAPublicKey _parsePublicKeyFromPem(String pem) {
    try {
      print('🔑 Parseando clave pública desde PEM...');
      
      // Eliminar headers y footers
      final rows = pem
          .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
          .replaceAll('-----END RSA PUBLIC KEY-----', '')
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      
      final keyBytes = base64.decode(rows);
      print('📦 Bytes decodificados: ${keyBytes.length}');
      
      final asn1Parser = ASN1Parser(Uint8List.fromList(keyBytes));
      
      // Intentar parsear como PKCS#1 primero
      try {
        final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
        
        if (topLevelSeq.elements.length == 2) {
          // Es formato PKCS#1 (RSAPublicKey)
          final modulus = (topLevelSeq.elements[0] as ASN1Integer).valueAsBigInteger;
          final exponent = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
          
          print('✅ Modulus bits: ${modulus?.bitLength ?? 0}');
          print('✅ Exponent: $exponent');
          print('✅ Clave pública parseada (PKCS#1)');
          
          return RSAPublicKey(modulus, exponent);
        } else if (topLevelSeq.elements.length > 2) {
          // Puede ser formato PKCS#8 (SubjectPublicKeyInfo)
          // Extraer el BitString que contiene la clave real
          final bitString = topLevelSeq.elements[1] as ASN1BitString;
          final keyParser = ASN1Parser(bitString.valueBytes());
          final keySeq = keyParser.nextObject() as ASN1Sequence;
          
          final modulus = (keySeq.elements[0] as ASN1Integer).valueAsBigInteger;
          final exponent = (keySeq.elements[1] as ASN1Integer).valueAsBigInteger;
          
          print('✅ Clave pública parseada (PKCS#8)');
          return RSAPublicKey(modulus, exponent);
        }
      } catch (e) {
        print('⚠️ Error parseando como PKCS#1/8: $e');
        rethrow;
      }
      
      throw Exception('Formato de clave pública no reconocido');
    } catch (e, stackTrace) {
      print('❌ Error parseando clave pública: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Guarda la clave privada en almacenamiento seguro
  Future<void> _savePrivateKeyToStorage(RSAPrivateKey privateKey) async {
    final pemString = _encodePrivateKeyToPem(privateKey);
    await _storage.write(key: 'rsa_private_key', value: pemString);
    print('💾 Clave privada guardada en almacenamiento seguro');
  }

  /// Guarda la clave pública en Firestore
  Future<void> _savePublicKeyToFirestore(String userId, RSAPublicKey publicKey) async {
    final pemString = _encodePublicKeyToPem(publicKey);
    
    await _firestore.collection('users').doc(userId).set({
      'publicKey': pemString,
      'keyGeneratedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    print('☁️ Clave pública guardada en Firestore');
  }

  /// Carga las claves desde almacenamiento seguro
  Future<bool> _loadKeysFromStorage() async {
    try {
      final privatePem = await _storage.read(key: 'rsa_private_key');
      if (privatePem == null) {
        print('📭 No hay clave privada guardada');
        return false;
      }

      _privateKey = _parsePrivateKeyFromPem(privatePem);

      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data()?['publicKey'] == null) {
        print('📭 No hay clave pública en Firestore');
        return false;
      }

      _publicKey = _parsePublicKeyFromPem(userDoc.data()!['publicKey']);
      print('✅ Claves cargadas exitosamente desde almacenamiento');
      return true;
    } catch (e) {
      print('⚠️ Error cargando claves (serán regeneradas): $e');
      return false; // NO lanzar excepción, dejar que initialize() regenere
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

    print('🔐 Cifrando mensaje...');
    
    // Generar clave AES y IV
    final aesKey = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);

    print('🔑 Clave AES generada: ${aesKey.length} bytes');

    // Cifrar mensaje con AES
    final encrypter = encrypt.Encrypter(
      encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
    );
    final encryptedMessage = encrypter.encrypt(plainText, iv: iv);

    print('📝 Mensaje cifrado con AES');

    // Cifrar clave AES con RSA del destinatario
    final rsaEncrypter = encrypt.Encrypter(
      encrypt.RSA(
        publicKey: recipientPublicKey,
        encoding: encrypt.RSAEncoding.PKCS1, // ← IMPORTANTE
      ),
    );
    final encryptedKey = rsaEncrypter.encryptBytes(aesKey.bytes);

    print('🔑 Clave AES cifrada con RSA');

    final payload = {
      'encryptedMessage': encryptedMessage.base64,
      'encryptedKey': encryptedKey.base64,
      'iv': iv.base64,
      'version': '1.0',
    };

    print('✅ Cifrado completado');
    return jsonEncode(payload);
  } catch (e, stackTrace) {
    print('❌ Error cifrando mensaje: $e');
    print('📚 Stack trace: $stackTrace');
    rethrow;
  }
}

  /// Descifra un mensaje recibido (Chat humano)
Future<String> decryptMessage(String encryptedPayload) async {
  try {
    if (_privateKey == null) {
      throw Exception('Clave privada no disponible');
    }

    print('🔓 Descifrando mensaje...');
    
    final payload = jsonDecode(encryptedPayload) as Map<String, dynamic>;
    
    print('📦 Payload recibido:');
    print('  - encryptedKey length: ${payload['encryptedKey']?.toString().length ?? 0}');
    print('  - iv length: ${payload['iv']?.toString().length ?? 0}');
    print('  - encryptedMessage length: ${payload['encryptedMessage']?.toString().length ?? 0}');

    // Descifrar la clave AES con RSA
    final rsaEncrypter = encrypt.Encrypter(
      encrypt.RSA(
        privateKey: _privateKey,
        encoding: encrypt.RSAEncoding.PKCS1, // ← IMPORTANTE: Especificar encoding
      ),
    );
    
    final encryptedKey = encrypt.Encrypted.fromBase64(payload['encryptedKey']);
    
    print('🔑 Descifrando clave AES...');
    final aesKeyBytes = rsaEncrypter.decryptBytes(encryptedKey);
    print('✅ Clave AES descifrada: ${aesKeyBytes.length} bytes');
    
    final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes));

    // Descifrar el mensaje con AES
    final iv = encrypt.IV.fromBase64(payload['iv']);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
    );
    final encryptedMessage = encrypt.Encrypted.fromBase64(payload['encryptedMessage']);
    
    print('📝 Descifrando mensaje con AES...');
    final decrypted = encrypter.decrypt(encryptedMessage, iv: iv);
    print('✅ Mensaje descifrado exitosamente');
    
    return decrypted;
  } catch (e, stackTrace) {
    print('❌ Error descifrando mensaje: $e');
    print('📚 Stack trace: $stackTrace');
    return '[Mensaje cifrado - No se puede descifrar]';
  }
}

 /// Cifra mensaje para Aurora AI (solo con clave del usuario)
Future<String> encryptForAI(String plainText) async {
  try {
    if (_publicKey == null) {
      throw Exception('Clave pública no disponible');
    }

    print('🔐 Cifrando mensaje para IA...');

    final aesKey = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(aesKey, mode: encrypt.AESMode.gcm),
    );
    final encryptedMessage = encrypter.encrypt(plainText, iv: iv);

    final rsaEncrypter = encrypt.Encrypter(
      encrypt.RSA(
        publicKey: _publicKey,
        encoding: encrypt.RSAEncoding.PKCS1, // ← IMPORTANTE
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

    print('✅ Mensaje cifrado para IA');
    return jsonEncode(payload);
  } catch (e) {
    print('❌ Error cifrando para IA: $e');
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
    print('🔄 Regenerando claves...');
    await _storage.delete(key: 'rsa_private_key');
    _publicKey = null;
    _privateKey = null;
    _publicKeyCache.clear();
    await generateAndStoreKeys();
    print('✅ Claves regeneradas correctamente');
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