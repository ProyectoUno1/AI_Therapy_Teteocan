import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

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

  Future<void> sendHumanMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final url = Uri.parse('$_baseUrl/chats/messages');
    
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
        }),
      );
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Error al enviar el mensaje');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Margar mensajes como leidos
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

  Future<String> getOrCreateChatId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ai/chat-id'), 
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chatId'];
      } else {
        throw Exception('Fallo al obtener/crear el ID del chat de IA: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de red o servidor al obtener el ID del chat de IA: $e');
    }
  }

   Future<String> sendAIMessage(String message) async {
    try {

      final response = await http.post(
        Uri.parse('$_baseUrl/chats/ai-chat/messages'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'message': message,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiMessage = data['aiMessage'] as String;
        return aiMessage;
      } else {
        final errorData = json.decode(response.body);
        final errorMsg = errorData['error'] ?? 'Error al enviar mensaje a IA';
        throw Exception(errorMsg);
      }
    } catch (e) {
      rethrow;
    }
  }


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
        final List<dynamic> jsonList = json.decode(response.body);
        
        return jsonList.map((json) {
          return MessageModel.fromJson({
            'id': json['id'] ?? '',
            'text': json['content'] ?? '', 
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
        final List<dynamic> jsonList = json.decode(response.body);
        
        return jsonList.map((json) {
          return MessageModel.fromJson({
            'id': json['id'] ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
            'text': json['text'] ?? '', 
            'isUser': json['isUser'] ?? false, 
            'senderId': json['senderId'] ?? '',
            'timestamp': json['timestamp'],
            'isRead': true, 
          });
        }).toList();
      } else {
        throw Exception('Error al cargar mensajes: ${response.statusCode}');
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
}