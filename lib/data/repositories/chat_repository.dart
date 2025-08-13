// lib/data/repositories/chat_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class ChatRepository {
  static const String _baseUrl = 'http://10.0.2.2:3000/api';
  final FirebaseAuth _auth = FirebaseAuth.instance; 

  ChatRepository();

  // Helper para obtener los encabezados, incluyendo el token de autenticación
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

  // Obtiene el ID del chat de IA
  Future<String> getAIChatId() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ai/chat-id'),
        headers: await _getHeaders(), // Envía los encabezados con el token
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
        headers: await _getHeaders(), // Envía los encabezados con el token
        body: jsonEncode({
          'chatId': chatId,
          'message': message,
        }),
      );

      if (kDebugMode) print('sendAIMessage response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['aiMessage'];
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
        headers: await _getHeaders(), 
      );

      if (kDebugMode) print('loadMessages response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
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