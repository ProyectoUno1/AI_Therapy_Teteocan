// lib/data/repositories/psychology_payment_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';

abstract class PsychologyPaymentRepository {
  Future<Map<String, dynamic>> createPsychologySession({
    required String userEmail,
    required String userId,
    String? userName,
    required String sessionDate,
    required String sessionTime,
    required String psychologistName,
    required String psychologistId,
    String? sessionNotes,
  });

  Future<Map<String, dynamic>> verifyPsychologySession({
    required String sessionId,
  });

  Future<List<Map<String, dynamic>>> getPsychologySessions({
    required String userId,
    String? status,
    int limit = 10,
  });
}

class PsychologyPaymentRepositoryImpl implements PsychologyPaymentRepository {
  final http.Client _client;
  
  // Usar tu configuración de API existente
  static const String _baseUrl = '${ApiConstants.baseUrl}/api/stripe';

  PsychologyPaymentRepositoryImpl({http.Client? client}) 
      : _client = client ?? http.Client();

  @override
  Future<Map<String, dynamic>> createPsychologySession({
    required String userEmail,
    required String userId,
    String? userName,
    required String sessionDate,
    required String sessionTime,
    required String psychologistName,
    required String psychologistId,
    String? sessionNotes,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/create-psychology-session'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'userEmail': userEmail,
          'userId': userId,
          'userName': userName,
          'sessionDate': sessionDate,
          'sessionTime': sessionTime,
          'psychologistName': psychologistName,
          'psychologistId': psychologistId,
          'sessionNotes': sessionNotes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'checkoutUrl': data['checkoutUrl'],
          'sessionId': data['sessionId'],
          'psychologySessionId': data['psychologySessionId'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error creando sesión de pago');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyPsychologySession({
    required String sessionId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/verify-psychology-session'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sessionId': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error verificando sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPsychologySessions({
    required String userId,
    String? status,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$_baseUrl/psychology-sessions/$userId')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error obteniendo sesiones');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}