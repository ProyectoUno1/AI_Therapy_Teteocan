// lib/data/datasources/psychologist_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';

class PsychologistRemoteDataSource {
  static final String _baseUrl = '${ApiConstants.baseUrl}/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final user = _auth.currentUser;
    if (user != null) {
      final idToken = await user.getIdToken(false); 
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
    }
    return headers;
  }

  // INFORMACIÓN BÁSICA
  
  Future<void> updateBasicInfo({
    required String uid,
    String? username,
    String? email,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (profilePictureUrl != null) data['profilePictureUrl'] = profilePictureUrl;

    if (data.isEmpty) return;

    final response = await http.patch(
      Uri.parse('$_baseUrl/psychologists/$uid/basic'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // INFORMACIÓN PROFESIONAL

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
    double? price,
  }) async {

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
    if (price != null) data['price'] = price;

    if (data.isEmpty) {
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/psychologists/$uid/professional'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió en 30 segundos');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }

    } catch (e) {
      rethrow;
    }
  }

  // OBTENER INFORMACIÓN
  
  Future<PsychologistModel?> getPsychologistInfo(String uid) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/psychologists/$uid'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final psychologistData = responseData['psychologist'];
      return PsychologistModel.fromJson(psychologistData);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // SUBIDA DE IMAGEN 
  Future<String> uploadProfilePicture(String imagePath) async {
    final String apiUrl = '$_baseUrl/psychologists/upload-profile-picture';

    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('imageFile', imagePath));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['profilePictureUrl'];
    } else {
      final errorBody = json.decode(response.body);
      throw Exception('Error al subir imagen: ${errorBody['error']} (${response.statusCode})');
    }
  }
}