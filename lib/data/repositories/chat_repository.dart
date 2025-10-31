// lib/data/repositories/chat_repository.dart
// ✅ VERSIÓN CORREGIDA: Se calcula 'isUser' correctamente

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';

class ChatRepository {
  static const String _baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // ============== CHAT CON IA (AURORA) ==============

  Future<String> sendAIMessage(String message) async {
    try {
      print('📤 Enviando mensaje a IA: ${message.substring(0, message.length > 30 ? 30 : message.length)}...');

      final response = await http.post(
        Uri.parse('$_baseUrl/chats/ai-chat/messages'),
        headers: await _getHeaders(),
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['aiMessage'] ?? 'Sin respuesta';
        print('✅ Respuesta IA recibida: ${aiMessage.substring(0, aiMessage.length > 30 ? 30 : aiMessage.length)}...');
        return aiMessage;
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
      print('📥 Cargando mensajes de IA...');
      
      final currentUserId = _auth.currentUser?.uid; // Obtener el ID del usuario

      if (currentUserId == null) {
        throw Exception('Usuario no autenticado para cargar mensajes.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chats/ai-chat/messages'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('✅ ${jsonList.length} mensajes de IA recibidos');
        
        return jsonList.map((json) => MessageModel.fromJson({
          'id': json['id'] ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
          'text': json['text'] ?? '',
          // ✅ CORRECCIÓN CLAVE: Calcular isUser comparando senderId con el ID del usuario.
          // Si el senderId del mensaje es igual al ID del usuario actual, entonces isUser es true.
          'isUser': json['senderId'] == currentUserId, 
          'senderId': json['senderId'] ?? '',
          'timestamp': json['timestamp'],
          'isRead': true,
        })).toList();
      } else {
        throw Exception('Error cargando mensajes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error cargando mensajes IA: $e');
      rethrow;
    }
  }

  // ============== CHAT CON HUMANOS ==============

  Future<void> sendHumanMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      print('📤 Enviando mensaje humano...');
      print('   - Chat ID: $chatId');
      print('   - De: $senderId');
      print('   - Para: $receiverId');
      print('   - Contenido: ${content.substring(0, content.length > 30 ? 30 : content.length)}...');

      final url = Uri.parse('$_baseUrl/chats/messages');
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content, // Texto plano, se encripta en backend
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMessage = 'Error al enviar el mensaje. Código: ${response.statusCode}';
        
        try {
          final body = jsonDecode(response.body);
          errorMessage = body['error'] ?? errorMessage;
        } catch (_) {
          // Respuesta HTML, usar mensaje por defecto
        }
        
        throw Exception(errorMessage);
      }
      
      print('✅ Mensaje enviado correctamente');
    } catch (e) {
      print('❌ Error enviando mensaje humano: $e');
      rethrow;
    }
  }

  Future<List<MessageModel>> loadMessages(String chatId) async {
    try {
      // Si es chat con IA, usar método específico
      if (chatId == _auth.currentUser?.uid || chatId.contains('ai')) {
        return await loadAIChatMessages();
      }

      print('📥 Cargando mensajes del chat: $chatId');

      final response = await http.get(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('✅ ${jsonList.length} mensajes recibidos del backend');
        
        // El backend ya desencriptó los mensajes, solo parseamos
        return jsonList.map((json) {
          final content = json['content'] ?? '';
          
          print('📦 Mensaje ID: ${json['id']}');
          print('   - Contenido: ${content.substring(0, content.length > 30 ? 30 : content.length)}...');
          
          return MessageModel.fromJson({
            'id': json['id'] ?? '',
            'text': content,
            'isUser': json['senderId'] == _auth.currentUser?.uid,
            'senderId': json['senderId'] ?? '',
            'receiverId': json['receiverId'],
            'timestamp': json['timestamp'],
            'isRead': json['isRead'] ?? false,
          });
        }).toList();
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
        body: jsonEncode({'userId': currentUserId}),
      );
      
      if (response.statusCode != 200) {
        String errorMessage = 'Error al marcar mensajes como leídos. Código: ${response.statusCode}';

        try {
          final body = jsonDecode(response.body);
          errorMessage = body['error'] ?? errorMessage;
        } catch (_) {
          // Captura FormatException si la respuesta es HTML
        }
        
        throw Exception(errorMessage);
      }
      
      print('✅ Mensajes marcados como leídos');
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

      if (messagesSnapshot.docs.isEmpty) {
        print('ℹ️ No hay mensajes sin leer');
        return;
      }

      final batch = _firestore.batch();
      
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      print('✅ ${messagesSnapshot.docs.length} mensajes marcados como leídos en Firestore');
    } catch (e) {
      print('❌ Error en markMessagesAsReadFirestore: $e');
    }
  }

  Future<String> getOrCreateChatId(String userId) async {
    try {
      print('📋 Obteniendo/creando chat ID para usuario: $userId');

      final response = await http.get(
        Uri.parse('$_baseUrl/chats/ai-chat/chat-id'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chatId = data['chatId'];
        print('✅ Chat ID obtenido: $chatId');
        return chatId;
      } else {
        throw Exception('Fallo al obtener/crear el ID del chat de IA');
      }
    } catch (e) {
      print('❌ Error al obtener el ID del chat de IA: $e');
      throw Exception('Error al obtener el ID del chat de IA: $e');
    }
  }

  // ============== MÉTODOS DE LIMPIEZA (OPCIONAL) ==============

  /// Elimina todos los mensajes de un chat (útil para desarrollo/testing)
  Future<void> clearChatMessages(String chatId) async {
    try {
      print('🗑️ Eliminando mensajes del chat: $chatId');

      final url = Uri.parse('$_baseUrl/chats/$chatId/messages');
      
      final response = await http.delete(
        url,
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ ${data['count']} mensajes eliminados');
      } else {
        throw Exception('Error eliminando mensajes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error eliminando mensajes: $e');
      rethrow;
    }
  }
}