// lib/data/datasources/emotion_data_source.dart
// ✅ VERSIÓN CORREGIDA: Rutas consistentes

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
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  // Método helper para hacer requests autenticados
  Future<http.Response> _authenticatedPost(String url, Map<String, dynamic> body) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    print('📤 POST: $url');
    print('📦 Body: ${json.encode(body)}');

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

    print('📥 GET: $url');

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

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al guardar emoción: ${response.body}');
      }
    } catch (e) {
      print('Error en saveEmotion: $e');
      rethrow;
    }
  }

  @override
  Future<List<Emotion>> getPatientEmotions(String patientId) async {
    try {
      // ✅ Ruta consistente
      final response = await _authenticatedGet(
        '$baseUrl/patient-management/patients/$patientId/emotions',
      );

      print('📊 Respuesta getPatientEmotions: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ ${data.length} emociones cargadas');
        return data.map((item) => Emotion.fromMap(item)).toList();
      } else {
        throw Exception('Error al obtener emociones: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getPatientEmotions: $e');
      rethrow;
    }
  }

  @override
  Future<Emotion?> getTodayEmotion(String patientId) async {
    try {
      print('🔍 Buscando emoción de hoy para: $patientId');
      
      // ✅ Ruta consistente
      final response = await _authenticatedGet(
        '$baseUrl/patient-management/patients/$patientId/emotions/today',
      );

      print('📊 Respuesta getTodayEmotion: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        
        // Si la respuesta es "null" o vacía, no hay emoción hoy
        if (responseBody.isEmpty || responseBody == 'null' || responseBody == '{}') {
          print('ℹ️ No hay emoción registrada hoy');
          return null;
        }
        
        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          if (data.isEmpty) {
            print('ℹ️ Respuesta vacía, no hay emoción hoy');
            return null;
          }
          
          print('✅ Emoción de hoy encontrada: ${data['feeling']}');
          return Emotion.fromMap(data);
        } catch (e) {
          print('⚠️ Error parseando respuesta: $e');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ No hay emoción registrada hoy (404)');
        return null;
      } else {
        print('⚠️ Error ${response.statusCode}, intentando método alternativo');
        return _getTodayEmotionAlternative(patientId);
      }
    } catch (e) {
      print('❌ Error en getTodayEmotion: $e');
      return _getTodayEmotionAlternative(patientId);
    }
  }

  // Método alternativo para obtener la emoción de hoy
  Future<Emotion?> _getTodayEmotionAlternative(String patientId) async {
    try {
      print('🔄 Intentando método alternativo...');
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final emotions = await getEmotionsByDateRange(patientId, startOfDay, endOfDay);
      
      if (emotions.isNotEmpty) {
        print('✅ Emoción encontrada por método alternativo');
        return emotions.first;
      }
      
      print('ℹ️ No hay emoción hoy (método alternativo)');
      return null;
    } catch (e) {
      print('❌ Error en método alternativo: $e');
      return null;
    }
  }

  @override
  Future<List<Emotion>> getEmotionsByDateRange(
    String patientId, 
    DateTime start, 
    DateTime end
  ) async {
    try {
      final startIso = start.toIso8601String();
      final endIso = end.toIso8601String();
      
      print('📅 Buscando emociones entre $startIso y $endIso');
      
      // ✅ Ruta consistente
      final response = await _authenticatedGet(
        '$baseUrl/patient-management/patients/$patientId/emotions?start=$startIso&end=$endIso',
      );

      print('📊 Respuesta getEmotionsByDateRange: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final emotions = data.map((item) => Emotion.fromMap(item)).toList();
        print('✅ ${emotions.length} emociones encontradas en el rango');
        return emotions;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Error al obtener emociones: ${errorData['error']} - ${errorData['details']}'
        );
      }
    } catch (e) {
      print('❌ Error en getEmotionsByDateRange: $e');
      rethrow;
    }
  }
}