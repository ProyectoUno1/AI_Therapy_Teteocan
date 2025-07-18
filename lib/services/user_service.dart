import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class UserService {
  static const String _baseUrl = 'http://localhost:3000/api/users';
  final AuthService _authService = AuthService();

  // Obtener perfil del usuario
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      String? token = await _authService.refreshToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error al obtener perfil: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al obtener perfil: $e');
      return null;
    }
  }

  // Obtener mensajes AI del usuario
  Future<List<Map<String, dynamic>>?> getAIMessages() async {
    try {
      String? token = await _authService.refreshToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/ai-messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['messages']);
      } else {
        print('Error al obtener mensajes AI: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al obtener mensajes AI: $e');
      return null;
    }
  }

  // Obtener sesiones de terapia del usuario
  Future<List<Map<String, dynamic>>?> getTherapySessions() async {
    try {
      String? token = await _authService.refreshToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/therapy-sessions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['sessions']);
      } else {
        print('Error al obtener sesiones: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al obtener sesiones: $e');
      return null;
    }
  }

  // Enviar mensaje AI (para futuras implementaciones)
  Future<Map<String, dynamic>?> sendAIMessage(String message) async {
    try {
      String? token = await _authService.refreshToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/ai-messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Error al enviar mensaje AI: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al enviar mensaje AI: $e');
      return null;
    }
  }
}
