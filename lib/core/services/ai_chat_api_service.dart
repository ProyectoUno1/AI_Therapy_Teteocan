// lib/core/services/ai_chat_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AiChatApiService {
  final String _baseUrl = 'http://10.0.2.2:3000/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> sendMessage(String message) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado.');
    }

    final idToken = await user.getIdToken();
    final url = Uri.parse('$_baseUrl/chats/ai-chat/messages');
    
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
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Error al enviar mensaje al backend.');
    }
  }
}