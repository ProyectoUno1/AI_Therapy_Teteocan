// lib/data/datasources/emotion_data_source.dart
import 'package:ai_therapy_teteocan/data/models/emotion_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

abstract class EmotionDataSource {
  Future<void> saveEmotion(Emotion emotion);
  Future<List<Emotion>> getPatientEmotions(String patientId);
  Future<Emotion?> getTodayEmotion(String patientId);
  Future<List<Emotion>> getEmotionsByDateRange(String patientId, DateTime start, DateTime end);
}

class EmotionRemoteDataSource implements EmotionDataSource {
  final String baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  EmotionRemoteDataSource({required this.baseUrl});

  // Método helper para obtener el token de Firebase
  Future<String?> _getAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        return token;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Método helper para hacer requests autenticados
  Future<http.Response> _authenticatedPost(String url, Map<String, dynamic> body) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    return await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );
  }

  Future<http.Response> _authenticatedGet(String url) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    return await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  @override
  Future<void> saveEmotion(Emotion emotion) async {
    try {
      final response = await _authenticatedPost(
        '$baseUrl/patient-management/emotions',
        emotion.toMap(),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al guardar emoción: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Emotion>> getPatientEmotions(String patientId) async {
    try {
      final response = await _authenticatedGet(
        '$baseUrl/api/patient-management/patients/$patientId/emotions',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Emotion.fromMap(item)).toList();
      } else {
        throw Exception('Error al obtener emociones: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
Future<Emotion?> getTodayEmotion(String patientId) async {
  try {
    final response = await _authenticatedGet(
      '$baseUrl/api/patient-management/patients/$patientId/emotions/today',
    );

    if (response.statusCode == 200) {
      // Mejorar la validación de respuesta vacía
      final responseBody = response.body.trim();
      if (responseBody.isEmpty || responseBody == 'null' || responseBody == '{}') {
        return null;
      }
      
      try {
        final Map<String, dynamic> data = json.decode(responseBody);
        if (data.isEmpty) return null;
        return Emotion.fromMap(data);
      } catch (e) {
        print('Error parsing emotion response: $e');
        return null;
      }
    } else if (response.statusCode == 404) {
      return _getTodayEmotionAlternative(patientId);
    } else {
      print('Server error: ${response.statusCode} - ${response.body}');
      return _getTodayEmotionAlternative(patientId);
    }
  } catch (e) {
    print('Error in getTodayEmotion: $e');
    return _getTodayEmotionAlternative(patientId);
  }
}

  // Método alternativo para obtener la emoción de hoy
  Future<Emotion?> _getTodayEmotionAlternative(String patientId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final emotions = await getEmotionsByDateRange(patientId, startOfDay, endOfDay);
      return emotions.isNotEmpty ? emotions.first : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Emotion>> getEmotionsByDateRange(String patientId, DateTime start, DateTime end) async {
    try {
      final response = await _authenticatedGet(
        '$baseUrl/api/patient-management/patients/$patientId/emotions?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final emotions = data.map((item) => Emotion.fromMap(item)).toList();
        return emotions;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Error al obtener emociones: ${errorData['error']} - ${errorData['details']}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
