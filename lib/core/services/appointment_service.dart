import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';

class AppointmentService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // Obtener token de Firebase Auth
  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      log('Error obteniendo token: $e', name: 'AppointmentService');
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

  // Crear nueva cita
 Future<AppointmentModel> createAppointment({
    required String psychologistId,
    required DateTime scheduledDateTime,
    required AppointmentType type,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'psychologistId': psychologistId,
        'scheduledDateTime': scheduledDateTime.toUtc().toIso8601String(), // UTC
        'type': type.name,
        if (notes != null) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Verificar diferentes formatos de respuesta
        if (data['appointment'] != null) {
          return AppointmentModel.fromJson(data['appointment']);
        } else if (data['id'] != null) {
          return AppointmentModel.fromJson(data);
        } else {
          throw Exception('Formato de respuesta inesperado del servidor: $data');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? errorData['details'] ?? 'Error desconocido al crear la cita';
        throw Exception(errorMessage);
      }
    } catch (e) {
      
      if (e is FormatException) {
        throw Exception('Error de formato en la respuesta del servidor');
      } else if (e is http.ClientException) {
        throw Exception('Error de conexión: ${e.message}');
      } else if (e is Exception) {

        final message = e.toString();
        if (message.contains('Exception: ')) {
          throw Exception(message.split('Exception: ')[1]);
        }
        throw e;
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
      
      final uri = Uri.parse('$baseUrl/appointments').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

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
      final message = e.toString().contains('FormatException') ? 'Error de conexión con el servidor' : e.toString();
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
      
      if (psychologistNotes != null) body['psychologistNotes'] = psychologistNotes;
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
      final message = e.toString().contains('FormatException') ? 'Error de conexión con el servidor' : e.toString();
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
      final message = e.toString().contains('FormatException') ? 'Error de conexión con el servidor' : e.toString();
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
      final message = e.toString().contains('FormatException') ? 'Error de conexión con el servidor' : e.toString();
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
      final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      
      final url = '$baseUrl/appointments/available-slots/$psychologistId?startDate=$startDateStr&endDate=$endDateStr';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Verificar que availableSlots existe
        if (data['availableSlots'] == null) {
          return [];
        }
        
        final slotsList = data['availableSlots'] as List;
        
        return slotsList.map((json) => TimeSlot(
          time: json['time'] ?? '00:00',
          dateTime: DateTime.parse(json['dateTime']).toLocal(), 
          isAvailable: json['isAvailable'] ?? false,
          reason: json['reason'],
        )).toList();
      } else {
        throw Exception(_handleHttpError(response));
      }
    } catch (e) {
      
      // Manejo específico de errores
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

} 