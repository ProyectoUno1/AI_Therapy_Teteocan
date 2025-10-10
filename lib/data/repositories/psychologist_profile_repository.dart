// data/repositories/psychologist_profile_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart'; 

class PsychologistProfileRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _baseUrl = '${AppConstants.baseUrl}/psychologists'; 

  Future<String> uploadProfilePicture(String imagePath) async {
    final String apiUrl = '$_baseUrl/upload-profile-picture'; 

    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Usuario no autenticado para obtener el token.'); 
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'imageFile', 
          imagePath,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['profilePictureUrl']; 
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Fallo al subir la imagen: ${errorBody['error'] ?? 'Error desconocido'} (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al subir la imagen del psicólogo: $e');
    }
  }

}