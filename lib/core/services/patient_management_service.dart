import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';

class PatientManagementService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 10);

  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      log('Error getting token: $e', name: 'PatientManagementService');
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

  Future<List<PatientManagementModel>> getPatientsForPsychologist({
    required String psychologistId,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/patient-management/psychologist/$psychologistId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener pacientes');
      }

      final responseData = jsonDecode(response.body);
      final patientsList = responseData['patients'] as List;

      return patientsList
          .map((json) => PatientManagementModel.fromJson(json))
          .toList();
    } catch (e) {
      log('Error al obtener pacientes: $e', name: 'PatientManagementService');
      throw Exception('Error al cargar pacientes: ${e.toString()}');
    }
  }

  // Obtener detalles específicos de un paciente
  Future<PatientManagementModel?> getPatientDetails(String patientId) async {
    try {
      final psychologistId = FirebaseAuth.instance.currentUser?.uid;
      if (psychologistId == null) {
        throw Exception("Psychologist not authenticated.");
      }
      final allPatients = await getPatientsForPsychologist(
        psychologistId: psychologistId,
      );
      return allPatients.where((p) => p.id == patientId).isNotEmpty
          ? allPatients.firstWhere((p) => p.id == patientId)
          : null;
    } catch (e) {
      log(
        'Error al obtener detalles del paciente: $e',
        name: 'PatientManagementService',
      );
      throw Exception('Error al cargar detalles del paciente: ${e.toString()}');
    }
  }
}
