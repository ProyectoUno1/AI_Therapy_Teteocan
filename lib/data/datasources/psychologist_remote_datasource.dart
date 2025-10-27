// lib/data/datasources/psychologist_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';

class PsychologistRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Construir baseUrl correctamente
  String get _baseUrl {
    final base = ApiConstants.baseUrl;
    // Si ya tiene /api, no duplicar
    if (base.endsWith('/api')) {
      return base;
    }
    return '$base/api';
  }

  Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    final idToken = await user.getIdToken(false);
    if (idToken == null) {
      throw Exception('No se pudo obtener el token de autenticación');
    }

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $idToken',
    };
  }

  // ================== INFORMACIÓN BÁSICA ==================
  
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

    final url = Uri.parse('$_baseUrl/psychologists/$uid/basic');
    print('📡 PATCH $url');
    print('📦 Body: ${jsonEncode(data)}');

    final response = await http.patch(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Timeout: El servidor no respondió en 30 segundos');
      },
    );

    print('📡 Status: ${response.statusCode}');
    print('📡 Response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // ================== INFORMACIÓN PROFESIONAL ==================

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
      print('⚠️ No hay datos para actualizar');
      return;
    }

    final url = Uri.parse('$_baseUrl/psychologists/$uid/professional-info');
    print('📡 PATCH $url');
    print('📦 Body: ${jsonEncode(data)}');

    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió en 30 segundos');
        },
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Información profesional actualizada exitosamente');
      } else {
        final errorBody = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'error': 'Error desconocido'};
        throw Exception('Error ${response.statusCode}: ${errorBody['error'] ?? errorBody}');
      }

    } catch (e) {
      print('❌ Error en updateProfessionalInfo: $e');
      rethrow;
    }
  }

  // ================== OBTENER INFORMACIÓN ==================
  
  Future<PsychologistModel?> getPsychologistInfo(String uid) async {
    final url = Uri.parse('$_baseUrl/psychologists/$uid');
    print('📡 GET $url');

    try {
      final headers = await _getHeaders();
      print('🔑 Headers: ${headers.keys.join(", ")}');
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al obtener información del psicólogo');
        },
      );

      print('📡 Status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('📦 Response data keys: ${responseData.keys.join(", ")}');
        
        // El backend puede devolver { psychologist: {...} } o directamente {...}
        final psychologistData = responseData.containsKey('psychologist')
            ? responseData['psychologist']
            : responseData;
        
        print('✅ Psicólogo obtenido exitosamente');
        print('📋 Datos del psicólogo: ${psychologistData.keys.join(", ")}');
        
        return PsychologistModel.fromJson(psychologistData);
        
      } else if (response.statusCode == 403) {
        print('⚠️ Acceso no autorizado (403)');
        print('📄 Response: ${response.body}');
        return null;
      } else if (response.statusCode == 404) {
        print('⚠️ Psicólogo no encontrado (404)');
        print('📄 Response: ${response.body}');
        return null;
      } else {
        print('❌ Error ${response.statusCode}');
        print('📄 Response: ${response.body}');
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error obteniendo psicólogo: $e');
      rethrow;
    }
  }

  // ================== SUBIDA DE IMAGEN ==================
  
  Future<String> uploadProfilePicture(String imagePath) async {
    final apiUrl = '$_baseUrl/psychologists/upload-profile-picture';
    print('📡 POST $apiUrl');
    print('📸 Imagen: $imagePath');

    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('imageFile', imagePath)
      );

      print('📤 Enviando imagen...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final imageUrl = jsonResponse['profilePictureUrl'] as String;
        print('✅ Imagen subida exitosamente: $imageUrl');
        return imageUrl;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Error al subir imagen: ${errorBody['error']} (${response.statusCode})');
      }
    } catch (e) {
      print('❌ Error en uploadProfilePicture: $e');
      rethrow;
    }
  }
}