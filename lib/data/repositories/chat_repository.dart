// lib/data/repositories/chat_repository.dart
// ✅ VERSIÓN CON DEBUG MEJORADO

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/core/services/e2ee_service.dart';

class ChatRepository {
  static const String _baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final E2EEService _e2eeService = E2EEService();

  ChatRepository();

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final user = _auth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken(true);
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      } else {
        throw Exception('No se pudo obtener el token de autenticación.');
      }
    } else {
      throw Exception('Usuario no autenticado.');
    }

    return headers;
  }

  // ============== CHAT CON IA (AURORA) - CON E2EE ==============

  Future<String> sendAIMessage(String message) async {
    try {
      final encryptedMessage = await _e2eeService.encryptForAI(message);

      final response = await http.post(
        Uri.parse('$_baseUrl/chats/ai-chat/messages'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'message': message,
          'encryptedForStorage': encryptedMessage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['aiMessage'] != null) {
          final aiMessage = data['aiMessage'];
          
          if (aiMessage.toString().startsWith('{')) {
            try {
              return await _e2eeService.decryptFromAI(aiMessage);
            } catch (e) {
              print('⚠️ Error descifrando respuesta IA: $e');
              return aiMessage;
            }
          }
          
          return aiMessage;
        }
        
        throw Exception('Respuesta inválida del servidor');
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Límite de mensajes alcanzado');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error enviando mensaje IA: $e');
      rethrow;
    }
  }

  Future<List<MessageModel>> loadAIChatMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chats/ai-chat/messages'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        
        final messages = <MessageModel>[];
        
        for (var json in jsonList) {
          String decryptedContent;
          
          try {
            final text = json['text'] ?? '';
            
            if (text.startsWith('{') && text.contains('encryptedMessage')) {
              decryptedContent = await _e2eeService.decryptFromAI(text);
            } else {
              decryptedContent = text;
            }
          } catch (e) {
            print('⚠️ Error descifrando mensaje: $e');
            decryptedContent = '[Mensaje cifrado]';
          }

          messages.add(MessageModel.fromJson({
            'id': json['id'] ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
            'text': decryptedContent,
            'isUser': json['isUser'] ?? false,
            'senderId': json['senderId'] ?? '',
            'timestamp': json['timestamp'],
            'isRead': true,
          }));
        }

        return messages;
      } else {
        throw Exception('Error cargando mensajes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error cargando mensajes IA: $e');
      rethrow;
    }
  }

  // ============== CHAT CON HUMANOS - CON E2EE ==============

  Future<void> sendHumanMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      print('🔐 Cifrando mensaje para: $receiverId');
      
      final encryptedContent = await _e2eeService.encryptMessage(
        content,
        receiverId,
      );

      print('✅ Mensaje cifrado, enviando al backend...');

      final url = Uri.parse('$_baseUrl/chats/messages');
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'content': encryptedContent, // Cifrado para destinatario
          'plainTextForSender': content, // ✅ Texto plano para remitente
          'isE2EE': true,
        }),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Error al enviar el mensaje');
      }
      
      print('✅ Mensaje enviado correctamente');
    } catch (e) {
      print('❌ Error enviando mensaje humano: $e');
      rethrow;
    }
  }

  /// ✅ VERSIÓN CORREGIDA: Procesar correctamente isE2EE del backend
  Future<List<MessageModel>> loadMessages(String chatId) async {
    try {
      if (chatId == _auth.currentUser?.uid || chatId.contains('ai')) {
        return await loadAIChatMessages();
      }

      print('🔥 Cargando mensajes del chat: $chatId');

      final response = await http.get(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('✅ ${jsonList.length} mensajes recibidos del backend');
        
        final messages = <MessageModel>[];
        
        for (var json in jsonList) {
          String decryptedContent;
          final content = json['content'] ?? '';
          final isE2EE = json['isE2EE'] ?? false;
          
          print('📦 Mensaje ID: ${json['id']}');
          print('   - isE2EE: $isE2EE');
          print('   - Primeros 30 chars: ${content.substring(0, content.length > 30 ? 30 : content.length)}');
          
          try {
            // ✅ Verificar si es JSON cifrado
            if (content.trim().startsWith('{')) {
              try {
                final parsed = jsonDecode(content);
                if (parsed['encryptedMessage'] != null) {
                  print('🔓 Descifrando mensaje...');
                  decryptedContent = await _e2eeService.decryptMessage(content);
                  print('✅ Descifrado: ${decryptedContent.substring(0, decryptedContent.length > 30 ? 30 : decryptedContent.length)}');
                } else {
                  decryptedContent = content;
                }
              } catch (jsonError) {
                // No es JSON válido, es texto plano
                decryptedContent = content;
              }
            } else if (isE2EE) {
              // Flag E2EE pero no parece JSON
              print('⚠️ Flag isE2EE=true pero contenido no parece cifrado');
              try {
                decryptedContent = await _e2eeService.decryptMessage(content);
              } catch (e) {
                print('❌ Error descifrando: $e');
                decryptedContent = '[Mensaje cifrado - Error al descifrar]';
              }
            } else {
              // Mensaje en texto plano
              print('📄 Mensaje en texto plano');
              decryptedContent = content;
            }
          } catch (e) {
            print('❌ Error procesando mensaje: $e');
            
            if (e.toString().contains('Unsupported block type')) {
              decryptedContent = '🔒 [Mensaje cifrado con clave anterior]';
            } else {
              decryptedContent = '[Error al descifrar mensaje]';
            }
          }
          
          messages.add(MessageModel.fromJson({
            'id': json['id'] ?? '',
            'text': decryptedContent,
            'isUser': json['senderId'] == _auth.currentUser?.uid,
            'senderId': json['senderId'] ?? '',
            'receiverId': json['receiverId'],
            'timestamp': json['timestamp'],
            'isRead': json['isRead'] ?? false,
          }));
        }
        
        print('✅ Total mensajes procesados: ${messages.length}');
        return messages;
      } else {
        throw Exception('Error al cargar mensajes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error cargando mensajes: $e');
      rethrow;
    }
  }

  // ============== MÉTODOS AUXILIARES ==============

  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    final url = Uri.parse('$_baseUrl/chats/$chatId/mark-read');
    
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'userId': currentUserId,
        }),
      );
      
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Error al marcar mensajes como leídos');
      }
    } catch (e) {
      print('❌ Error marcando mensajes como leídos: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsReadFirestore({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      if (messagesSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print('❌ Error en markMessagesAsReadFirestore: $e');
    }
  }

  Future<String> getOrCreateChatId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ai/chat-id'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['chatId'];
      } else {
        throw Exception('Fallo al obtener/crear el ID del chat de IA');
      }
    } catch (e) {
      throw Exception('Error al obtener el ID del chat de IA: $e');
    }
  }

  Future<bool> ensureKeysExist() async {
    final hasKeys = await _e2eeService.hasKeys();
    if (!hasKeys) {
      await _e2eeService.initialize();
    }
    return true;
  }
}