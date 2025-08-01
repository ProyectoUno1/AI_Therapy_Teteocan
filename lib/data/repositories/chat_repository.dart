// lib/data/repositories/chat_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http; // Asegúrate de haber añadido http a pubspec.yaml
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:flutter/foundation.dart'; // Para `kDebugMode`

class ChatRepository {
  // Asegúrate de que esta URL apunte a tu backend de Node.js
  // Si usas un emulador de Android, '10.0.2.2' es la IP para 'localhost' de tu máquina.
  // Si usas iOS Simulator, 'localhost' funciona.
  // Si estás en un dispositivo físico, necesitarás la IP de tu máquina en la red local.
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; // O 'http://localhost:3000/api' para iOS/desktop

  // TODO: Gestionar el token de autenticación de Firebase
  // En una aplicación real, obtendrías el token de Firebase Auth del usuario loggeado.
  // Este token se enviará en los encabezados 'Authorization' a tu backend.
  String? _authToken; // Aquí almacenarías el token JWT de Firebase.

  // Constructor para inyectar token o dependencias si es necesario.
  // Por ahora, lo dejamos simple.
  ChatRepository();

  // Método para establecer el token de autenticación (lo llamarías después de que el usuario inicie sesión)
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

  // --- Comunicación con Backend ---

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
        headers: _getHeaders(), // Envía el token de auth
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

  // TODO: Añadir métodos para WebSockets si los implementas en el backend para mensajes en tiempo real.
}