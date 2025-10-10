import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

class PatientProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<String> uploadProfilePicture(String imagePath) async {
    const String apiUrl = '${AppConstants.baseUrl}/patients/upload-profile-picture'; 

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
      throw Exception('Error al subir la imagen a través del backend: $e');
    }
  }


  /// Obtener los datos del perfil del paciente desde Firestore
  Future<Map<String, dynamic>> fetchProfileData() async {
    final userUid = _auth.currentUser?.uid;

    if (userUid == null) {
      throw Exception('Usuario no autenticado.');
    }

    final DocumentSnapshot doc = await _firestore
        .collection('patients')
        .doc(userUid)
        .get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      throw Exception('Perfil de paciente no encontrado.');
    }
  }
  
  /// Actualizar un campo específico del perfil mediante la API backend
  Future<void> updateProfile({
    required String field,
    required dynamic value,
  }) async {
    const String apiUrl = '${AppConstants.baseUrl}/patients/profile'; 

    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('No se pudo obtener el token de autenticación.');
    }

    // Mapeo de campos a nombres que espera el backend
    final Map<String, dynamic> body = {};
    
    switch (field) {
      case 'profile_picture_url':
        body['profilePictureUrl'] = value;
        break;
      case 'username':
        body['username'] = value;
        break;
      case 'phoneNumber':
        body['phoneNumber'] = value;
        break;
      case 'dateOfBirth':
        body['dateOfBirth'] = value;
        break;
      case 'popupNotifications':
        body['popupNotifications'] = value;
        break;
      case 'emailNotifications':
        body['emailNotifications'] = value;
        break;
      default:
        body[field] = value;
    }

    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Fallo al actualizar el perfil: ${response.body}');
    }
  }

  /// Actualizar múltiples campos a la vez
  Future<void> updateMultipleFields(Map<String, dynamic> fields) async {
    const String apiUrl = '${AppConstants.baseUrl}/patients/profile';

    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('No se pudo obtener el token de autenticación.');
    }

    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(fields),
    );

    if (response.statusCode != 200) {
      throw Exception('Fallo al actualizar el perfil: ${response.body}');
    }
  }

  /// Stream para escuchar cambios en tiempo real del perfil
  Stream<Map<String, dynamic>> watchProfileData() {
    final userUid = _auth.currentUser?.uid;

    if (userUid == null) {
      throw Exception('Usuario no autenticado.');
    }

    return _firestore
        .collection('patients')
        .doc(userUid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        throw Exception('Perfil de paciente no encontrado.');
      }
    });
  }
}