// lib/core/services/patient_notes_service.dart

import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/patient_note.dart';

class PatientNotesService {
  static const String baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';

  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      log('Error getting token: $e', name: 'PatientNotesService');
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

  // Crear una nueva nota
  Future<PatientNote> createNote({
    required String patientId,
    required String title,
    required String content,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'patientId': patientId,
        'title': title,
        'content': content,
      });
      final response = await http.post(
        Uri.parse('$baseUrl/patient-management/notes'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear la nota');
      }

      final responseData = jsonDecode(response.body);

      // Retornar la nota creada con los datos del response
      return PatientNote(
        id: responseData['noteId'],
        patientId: patientId,
        psychologistId: FirebaseAuth.instance.currentUser?.uid ?? '',
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error al crear la nota: ${e.toString()}');
    }
  }

  // Obtener todas las notas de un paciente
  Future<List<PatientNote>> getPatientNotes(String patientId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/patient-management/patients/$patientId/notes'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener las notas');
      }

      final List<dynamic> notesData = jsonDecode(response.body);
      return notesData.map((json) => PatientNote.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar las notas: ${e.toString()}');
    }
  }

  // Actualizar una nota existente
  Future<PatientNote> updateNote({
    required String noteId,
    required String patientId,
    required String title,
    required String content,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'title': title,
        'content': content,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/patient-management/notes/$noteId'),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar la nota');
      }

      final responseData = jsonDecode(response.body);
      return PatientNote.fromJson(responseData['note']);
    } catch (e) {
      throw Exception('Error al actualizar la nota: ${e.toString()}');
    }
  }

  // Eliminar una nota
  Future<void> deleteNote(String noteId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/patient-management/notes/$noteId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar la nota');
      }
    } catch (e) {
      throw Exception('Error al eliminar la nota: ${e.toString()}');
    }
  }
}