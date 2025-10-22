// lib/core/services/ai_chat_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AiChatApiService {
  final String _baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> sendMessage(String message) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    final idToken = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/chats/ai-chat/messages');
    
    print('📤 Enviando mensaje a IA: "$message"');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiMessage = data['aiMessage'];
      print('📥 Respuesta de IA recibida: "$aiMessage"');
      return aiMessage;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Error al enviar mensaje al backend.');
    }
  }

  // ✅ NUEVO MÉTODO PARA CARGAR MENSAJES DE IA
  Future<List<dynamic>> loadAIChatMessages() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    final idToken = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/chats/ai-chat/messages');
    
    print('📥 Cargando mensajes de chat IA...');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> messages = jsonDecode(response.body);
      print('📨 Mensajes de IA cargados: ${messages.length} mensajes');
      
      // Log de depuración
      for (var msg in messages) {
        print('   💬 Mensaje: "${msg['content']}" | isAI: ${msg['isAI']}');
      }
      
      return messages;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Error al cargar mensajes del chat.');
    }
  }
}