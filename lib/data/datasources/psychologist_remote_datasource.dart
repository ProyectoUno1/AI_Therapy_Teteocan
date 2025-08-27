import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

class PsychologistRemoteDataSource {
  static const String _baseUrl = 'http://10.0.2.2:3000/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final user = _auth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken(true);
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }
    }
    return headers;
  }

  Future<void> updateBasicInfo({
    required String uid,
    String? username,
    String? email,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    print('Backend: Iniciando updateBasicInfo para $uid');

    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (profilePictureUrl != null) data['profilePictureUrl'] = profilePictureUrl;

    if (data.isEmpty) {
      print('Backend: No hay datos para actualizar.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/psychologists/$uid/basic-info'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
    } catch (e) {
      throw Exception('Error al actualizar la información básica: $e');
    }
  }

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
    print('Backend: Iniciando updateProfessionalInfo para $uid');

    // La variable `data` se define aquí.
    final Map<String, dynamic> data = {};
    if (fullName != null) data['fullName'] = fullName;
    if (professionalTitle != null) data['professionalTitle'] = professionalTitle;
    if (professionalLicense != null) data['professionalLicense'] = professionalLicense;
    if (yearsExperience != null) data['yearsExperience'] = yearsExperience;
    if (description != null) data['description'] = description;
    if (education != null) data['education'] = education;
    if (certifications != null) data['certifications'] = certifications;
    if (specialty != null) data['specialty'] = specialty;
    if (subSpecialties != null) data['subSpecialties'] = subSpecialties;
    if (schedule != null) data['schedule'] = schedule;
    if (profilePictureUrl != null) data['profilePictureUrl'] = profilePictureUrl;
    if (isAvailable != null) data['isAvailable'] = isAvailable;

    if (data.isEmpty) {
      print('Backend: No hay datos para actualizar.');
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/psychologists/$uid/public'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
    } catch (e) {
      throw Exception('Error al actualizar la información profesional: $e');
    }
  }

  Future<PsychologistModel?> getPsychologistInfo(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/psychologists/$uid/public'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PsychologistModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
            'Error al obtener la información del psicólogo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al obtener la información del psicólogo: $e');
    }
  }
}