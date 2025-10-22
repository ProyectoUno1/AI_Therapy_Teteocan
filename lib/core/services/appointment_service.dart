import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  static const String baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';

  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
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


 
  Future<String?> _getUserRoleFromFirestore(String uid) async {
    try {
      
      final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(uid).get();
      if (patientDoc.exists) {
        return patientDoc.data()?['role'];
      }
      final psychologistDoc = await FirebaseFirestore.instance.collection('psychologists').doc(uid).get();
      if (psychologistDoc.exists) {
        return psychologistDoc.data()?['role'];
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Crear nueva cita
  
Future<AppointmentModel> createAppointment({
  required String psychologistId,
  required String patientId,
  required DateTime scheduledDateTime,
  required AppointmentType type,
  String? notes,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    
    final url = Uri.parse('$baseUrl/appointments/');
    
    // ✅ IMPORTANTE: Enviar la fecha en formato ISO 8601 sin conversión
    final body = {
      'psychologistId': psychologistId,
      'patientId': patientId, 
      'scheduledDateTime': scheduledDateTime.toIso8601String(), // ✅ Sin .toUtc()
      'type': type.name,
      if (notes != null) 'notes': notes,
    };

    log('📤 Enviando cita:', name: 'AppointmentService');
    log('Fecha seleccionada: ${scheduledDateTime.toString()}', name: 'AppointmentService');
    log('Fecha ISO: ${scheduledDateTime.toIso8601String()}', name: 'AppointmentService');

    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    log('📥 Respuesta del servidor: ${response.statusCode}', name: 'AppointmentService');

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['appointment'] != null) {
        return AppointmentModel.fromJson(data['appointment']);
      } else if (data['id'] != null) {
        return AppointmentModel.fromJson(data);
      } else {
        throw Exception('Formato de respuesta inesperado del servidor: $data');
      }
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error'] ?? 
                          errorData['details'] ?? 
                          'Error desconocido al crear la cita';
      throw Exception(errorMessage);
    }
  } catch (e) {
    log('❌ Error en createAppointment: $e', name: 'AppointmentService');
    
    if (e is FormatException) {
      throw Exception('Error de formato en la respuesta del servidor');
    } else if (e is http.ClientException) {
      throw Exception('Error de conexión: ${e.message}');
    } else if (e is Exception) {
      final message = e.toString();
      if (message.contains('Exception: ')) {
        throw Exception(message.split('Exception: ')[1]);
      }
      rethrow;
    }
    throw Exception('Se ha producido un error inesperado al agendar la cita.');
  }
}
  // Obtener citas del usuario
  Future<List<AppointmentModel>> getAppointments({
    String? status,
    String? role,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse(
        '$baseUrl/appointments',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final appointmentsList = data['appointments'] as List;

        return appointmentsList
            .map((json) => AppointmentModel.fromJson(json))
            .toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener las citas');
      }
    } catch (e) {
      final message = e.toString().contains('FormatException')
          ? 'Error de conexión con el servidor'
          : e.toString();
      throw Exception(message);
    }
  }

  // Confirmar cita (psicólogos)
  Future<void> confirmAppointment({
    required String appointmentId,
    String? psychologistNotes,
    String? meetingLink,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      if (psychologistNotes != null)
        body['psychologistNotes'] = psychologistNotes;
      if (meetingLink != null) body['meetingLink'] = meetingLink;

      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$appointmentId/confirm'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al confirmar la cita');
      }
    } catch (e) {
      final message = e.toString().contains('FormatException')
          ? 'Error de conexión con el servidor'
          : e.toString();
      throw Exception(message);
    }
  }

  // Cancelar cita
  Future<void> cancelAppointment({
    required String appointmentId,
    required String reason,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {'reason': reason};

      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$appointmentId/cancel'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al cancelar la cita');
      }
    } catch (e) {
      final message = e.toString().contains('FormatException')
          ? 'Error de conexión con el servidor'
          : e.toString();
      throw Exception(message);
    }
  }

  // Completar cita (psicólogos)
  Future<void> completeAppointment({
    required String appointmentId,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      if (notes != null) body['notes'] = notes;

      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$appointmentId/complete'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al completar la cita');
      }
    } catch (e) {
      final message = e.toString().contains('FormatException')
          ? 'Error de conexión con el servidor'
          : e.toString();
      throw Exception(message);
    }
  }

  // Obtener horarios disponibles
  Future<List<TimeSlot>> getAvailableTimeSlots({
  required String psychologistId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    final headers = await _getHeaders();
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
    final startDateStr = '${normalizedStartDate.year}-${normalizedStartDate.month.toString().padLeft(2, '0')}-${normalizedStartDate.day.toString().padLeft(2, '0')}';
    final endDateStr = '${normalizedEndDate.year}-${normalizedEndDate.month.toString().padLeft(2, '0')}-${normalizedEndDate.day.toString().padLeft(2, '0')}';
    final url = '$baseUrl/appointments/available-slots/$psychologistId?startDate=$startDateStr&endDate=$endDateStr';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['availableSlots'] == null) {
        return [];
      }

      final slotsList = data['availableSlots'] as List;

      return slotsList
          .map(
            (json) => TimeSlot(
              time: json['time'] ?? '00:00',
              dateTime: DateTime.parse(json['dateTime']).toLocal(),
              isAvailable: json['isAvailable'] ?? false,
              reason: json['reason'],
            ),
          )
          .toList();
    } else {
      throw Exception(_handleHttpError(response));
    }
  } catch (e) {
    
    if (e is FormatException) {
      throw Exception('Error de formato en la respuesta del servidor');
    } else if (e is http.ClientException) {
      throw Exception('Error de conexión: ${e.message}');
    }

    throw Exception('Error al obtener horarios disponibles: ${e.toString()}');
  }
}

  String _handleHttpError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      return errorData['error'] ?? errorData['details'] ?? 'Error desconocido';
    } catch (e) {
      return 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
  }

  Future<void> rateAppointment({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {'rating': rating, if (comment != null) 'comment': comment};

      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$appointmentId/rate'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al calificar la cita');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> startAppointmentSession({required String appointmentId}) async {
    try {
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$appointmentId/start-session'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al iniciar la sesión');
      }
    } catch (e) {
      final message = e.toString().contains('FormatException')
          ? 'Error de conexión con el servidor'
          : e.toString();
      throw Exception(message);
    }
  }

  // Completar sesión de cita
  Future<void> completeAppointmentSession({
    required String appointmentId,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      if (notes != null) body['notes'] = notes;

      final response = await http.patch(
        Uri.parse('$baseUrl/appointments/$appointmentId/complete-session'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al completar la sesión');
      }
    } catch (e) {
      final message = e.toString().contains('FormatException')
          ? 'Error de conexión con el servidor'
          : e.toString();
      throw Exception(message);
    }
  }
}
