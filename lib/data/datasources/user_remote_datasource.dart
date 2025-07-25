// lib/data/datasources/user_remote_datasource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/models/user_model.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_models.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUserData(String uid);
  Future<UserModel> createUser({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required String role,
    String? professionalId,
  });
  Future<void> updatePatientProfile(PatientModel patient);
  Future<void> updatePsychologistProfile(PsychologistModel psychologist);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final http.Client client;

  UserRemoteDataSourceImpl({http.Client? client})
    : client = client ?? http.Client();

  @override
  Future<UserModel> getUserData(String uid) async {
    final url = '${AppConstants.baseUrl}/users/$uid';
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw UserNotFoundException(
          'Datos de usuario no encontrados en el backend.',
        );
      } else {
        throw FetchDataException(
          'Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw FetchDataException(
        'Error al obtener datos del usuario del backend: $e',
      );
    }
  }

  @override
  Future<UserModel> createUser({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required String role,
    String? professionalId,
  }) async {
    final url =
        '${AppConstants.baseUrl}/register'; // Tu endpoint de registro en Node.js
    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firebaseUid': uid,
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'role': role,
          if (professionalId != null) 'professionalId': professionalId,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw BadRequestException(
          'Error al crear usuario en el backend: ${response.body}',
        );
      }
    } catch (e) {
      throw FetchDataException(
        'Error al comunicarse con el backend para crear usuario: $e',
      );
    }
  }

  @override
  Future<void> updatePatientProfile(PatientModel patient) async {
    final url = '${AppConstants.baseUrl}/patients/${patient.uid}';
    try {
      final response = await client.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(patient.toJson()),
      );
      if (response.statusCode != 200) {
        throw BadRequestException(
          'Error al actualizar perfil de paciente: ${response.body}',
        );
      }
    } catch (e) {
      throw FetchDataException(
        'Error de conexión al actualizar perfil de paciente: $e',
      );
    }
  }

  @override
  Future<void> updatePsychologistProfile(PsychologistModel psychologist) async {
    final url = '${AppConstants.baseUrl}/psychologists/${psychologist.uid}';
    try {
      final response = await client.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(psychologist.toJson()),
      );
      if (response.statusCode != 200) {
        throw BadRequestException(
          'Error al actualizar perfil de psicólogo: ${response.body}',
        );
      }
    } catch (e) {
      throw FetchDataException(
        'Error de conexión al actualizar perfil de psicólogo: $e',
      );
    }
  }
}
