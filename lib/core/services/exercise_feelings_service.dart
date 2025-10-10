// lib/core/services/exercise_feelings_service.dart

import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/exercise_feeling_model.dart';

class ExerciseFeelingsService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      log('Error getting token: $e', name: 'ExerciseFeelingsService');
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Guardar sentimientos después de completar un ejercicio
  Future<ExerciseFeelingModel> saveExerciseFeeling({
    required String patientId,
    required String exerciseTitle,
    required int exerciseDuration,
    required String exerciseDifficulty,
    required String feeling,
    required int intensity,
    required String notes,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'patientId': patientId,
        'exerciseTitle': exerciseTitle,
        'exerciseDuration': exerciseDuration,
        'exerciseDifficulty': exerciseDifficulty,
        'feeling': feeling,
        'intensity': intensity,
        'notes': notes,
        'completedAt': (completedAt ?? DateTime.now()).toIso8601String(),
        'metadata': metadata ?? {},
      });

      final response = await http.post(
        Uri.parse('$baseUrl/patient-management/exercise-feelings'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 201) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Error al guardar sentimientos');
        } catch (e) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }

      final responseData = jsonDecode(response.body);

      // Retornar el sentimiento creado
      return ExerciseFeelingModel(
        id: responseData['exerciseFeelingId'],
        patientId: patientId,
        exerciseTitle: exerciseTitle,
        exerciseDuration: exerciseDuration,
        exerciseDifficulty: exerciseDifficulty,
        feeling: feeling,
        intensity: intensity,
        notes: notes,
        completedAt: completedAt ?? DateTime.now(),
        metadata: metadata,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      log('Error saving exercise feeling: $e', name: 'ExerciseFeelingsService');
      throw Exception('Error al guardar los sentimientos: ${e.toString()}');
    }
  }

  // Obtener historial de ejercicios completados
  Future<List<ExerciseFeelingModel>> getExerciseHistory({
    required String patientId,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/patient-management/patients/$patientId/exercise-history?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Error al obtener historial');
        } catch (e) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }

      final responseData = jsonDecode(response.body);
      final List<dynamic> historyData = responseData['exerciseHistory'];
      return historyData
          .map((json) => ExerciseFeelingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar el historial: ${e.toString()}');
    }
  }

  // Obtener ejercicios completados hoy
  Future<List<ExerciseFeelingModel>> getTodayExercises(
      String patientId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/patient-management/patients/$patientId/exercise-feelings/today'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
              errorData['error'] ?? 'Error al obtener ejercicios de hoy');
        } catch (e) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }

      final List<dynamic> todayData = jsonDecode(response.body);
      return todayData
          .map((json) => ExerciseFeelingModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Error al cargar ejercicios de hoy: ${e.toString()}');
    }
  }
}