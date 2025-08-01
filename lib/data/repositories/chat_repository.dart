// lib/data/repositories/chat_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http; 
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:flutter/foundation.dart'; 

class ChatRepository {
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; // O 'http://localhost:3000/api' 

  
  String? _authToken; 

 
  ChatRepository();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  // Helper para obtener los encabezados de la solicitud, incluyendo el token de auth
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }



  // Obtiene el ID del chat de IA para el usuario actual o lo crea
  Future<String> getAIChatId() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ai/chat-id'),
        headers: _getHeaders(), // Envía el token si está disponible
      );

      if (kDebugMode) print('getAIChatId response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chatId'];
      } else {
        throw Exception('Fallo al obtener el ID del chat de IA: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error en getAIChatId: $e');
      throw Exception('Error de red o servidor al obtener el ID del chat de IA: $e');
    }
  }

  // Envía un mensaje del usuario a la IA a través del backend
  Future<String> sendAIMessage(String chatId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/chat'),
        headers: _getHeaders(), 
        body: jsonEncode({
          'chatId': chatId,
          'message': message,
        }),
      );

      if (kDebugMode) print('sendAIMessage response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['aiMessage']; // El backend devuelve directamente el contenido de la IA
      } else {
        throw Exception('Fallo al enviar mensaje a la IA: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error en sendAIMessage: $e');
      throw Exception('Error de red o servidor al enviar mensaje a la IA: $e');
    }
  }

  // Carga el historial de mensajes para un chat específico
  Future<List<MessageModel>> loadMessages(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chats/$chatId/messages'),
        headers: _getHeaders(), // Envía el token de auth
      );

      if (kDebugMode) print('loadMessages response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        // Mapea la lista de JSON a una lista de MessageModel
        return jsonList.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw Exception('Fallo al cargar mensajes: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Error en loadMessages: $e');
      throw Exception('Error de red o servidor al cargar mensajes: $e');
    }
  }


}