// lib/data/datasources/psychologist_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart'; 

class PsychologistRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateBasicInfo({
    required String uid,
    String? username,
    String? email,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/psychologists/$uid/basic');
    final idToken = await _auth.currentUser?.getIdToken();

    if (idToken == null) {
      throw Exception('Usuario no autenticado.');
    }

    final Map<String, dynamic> body = {};
    if (username != null) body['fullName'] = username;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (profilePictureUrl != null) body['profilePictureUrl'] = profilePictureUrl;

    if (body.isEmpty) {
      return;
    }

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Error desconocido');
    }
  }

  // Método para actualizar la información profesional del psicólogo
  Future<void> updateProfessionalInfo({
    required String uid,
    String? fullName,
    String? professionalTitle,
    String? professionalLicense,
    int? yearsExperience,
    String? description,
    List<String>? education,
    List<String>? certifications,
    String? specialty,
    List<String>? subSpecialties,
    Map<String, dynamic>? schedule,
    String? profilePictureUrl,
    bool? isAvailable,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/psychologists/$uid/professional');
    final idToken = await _auth.currentUser?.getIdToken();

    if (idToken == null) {
      throw Exception('Usuario no autenticado.');
    }

    final Map<String, dynamic> body = {};
    if (fullName != null) body['fullName'] = fullName;
    if (professionalTitle != null) body['professionalTitle'] = professionalTitle;
    if (professionalLicense != null) body['professionalLicense'] = professionalLicense;
    if (yearsExperience != null) body['yearsExperience'] = yearsExperience;
    if (description != null) body['description'] = description;
    if (education != null) body['education'] = education;
    if (certifications != null) body['certifications'] = certifications;
    if (specialty != null) body['specialty'] = specialty;
    if (subSpecialties != null) body['subSpecialties'] = subSpecialties;
    if (schedule != null) body['schedule'] = schedule;
    if (profilePictureUrl != null) body['profilePictureUrl'] = profilePictureUrl;
    if (isAvailable != null) body['isAvailable'] = isAvailable; 

    if (body.isEmpty) {
      return;
    }

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Error desconocido');
    }
  }

  // Método para obtener la información completa del psicólogo
  Future<PsychologistModel?> getPsychologistInfo(String uid) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/psychologists/$uid/professional');
    final idToken = await _auth.currentUser?.getIdToken();

    if (idToken == null) {
      throw Exception('Usuario no autenticado.');
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return PsychologistModel.fromJson(data);
    } else if (response.statusCode == 404) {
      // Si el documento no existe, es un perfil nuevo.
      return null;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Error desconocido');
    }
  }
}