// lib/data/repositories/chat_repository.dart
// Repositorio actualizado con E2EE

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

  /// Envía mensaje cifrado a Aurora AI
  Future<String> sendAIMessage(String message) async {
    try {
      // 🔐 Cifrar mensaje antes de enviar
      final encryptedMessage = await _e2eeService.encryptForAI(message);

      final response = await http.post(
        Uri.parse('$_baseUrl/chats/ai-chat/messages'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'message': message, // Texto plano para Gemini
          'encryptedForStorage': encryptedMessage, // Cifrado para BD
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // La respuesta puede venir cifrada o en texto plano
        if (data['aiMessage'] != null) {
          final aiMessage = data['aiMessage'];
          
          // Intentar descifrar si viene en formato E2EE
          if (aiMessage.toString().startsWith('{')) {
            try {
              return await _e2eeService.decryptFromAI(aiMessage);
            } catch (e) {
              print('⚠️ Error descifrando respuesta IA: $e');
              return aiMessage; // Retornar texto plano si falla
            }
          }
          
          return aiMessage; // Ya está en texto plano
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

  /// Carga mensajes cifrados del chat con IA
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
            
            // Intentar descifrar si viene en formato E2EE
            if (text.startsWith('{') && text.contains('encryptedMessage')) {
              decryptedContent = await _e2eeService.decryptFromAI(text);
            } else {
              // Mensaje en texto plano (legacy o sistema)
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

  /// Envía mensaje cifrado entre humanos
  Future<void> sendHumanMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      // 🔐 Cifrar mensaje para el destinatario
      final encryptedContent = await _e2eeService.encryptMessage(
        content,
        receiverId,
      );

      final url = Uri.parse('$_baseUrl/chats/messages');
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'content': encryptedContent, // Enviar cifrado
          'isE2EE': true, // Flag para indicar E2EE
        }),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Error al enviar el mensaje');
      }
    } catch (e) {
      print('❌ Error enviando mensaje humano: $e');
      rethrow;
    }
  }

  /// Carga mensajes (descifrando en tiempo real desde Firestore)
  Future<List<MessageModel>> loadMessages(String chatId) async {
    try {
      if (chatId == _auth.currentUser?.uid || chatId.contains('ai')) {
        return await loadAIChatMessages();
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        
        final messages = <MessageModel>[];
        
        for (var json in jsonList) {
          String decryptedContent;
          
          try {
            final content = json['content'] ?? '';
            
            // Intentar descifrar si viene en formato E2EE
            if (content.startsWith('{') && content.contains('encryptedMessage')) {
              decryptedContent = await _e2eeService.decryptMessage(content);
            } else {
              // Mensaje en texto plano (legacy)
              decryptedContent = content;
            }
          } catch (e) {
            print('⚠️ Error descifrando mensaje: $e');
            decryptedContent = '[Mensaje cifrado]';
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
      print('Error en markMessagesAsReadFirestore: $e');
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

  /// Verifica que el usuario tenga claves E2EE configuradas
  Future<bool> ensureKeysExist() async {
    final hasKeys = await _e2eeService.hasKeys();
    if (!hasKeys) {
      await _e2eeService.initialize();
    }
    return true;
  }
}