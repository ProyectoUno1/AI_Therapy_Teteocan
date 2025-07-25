// lib/data/datasources/user_remote_datasource.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/data/models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<PatientModel> getPatientData(String authId);
  Future<PsychologistModel> getPsychologistData(String authId);
  Future<PatientModel> createPatient({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    String? dateOfBirth,
    required String idToken,
  });
  Future<PsychologistModel> createPsychologist({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required String professionalLicense,
    String? specialty,
    String? schedule,
    String? aboutMe,
    required String dateOfBirth,
  });
  Future<UserEntity> getUserData(String authId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final String baseUrl;
  final http.Client client;

  UserRemoteDataSourceImpl({required this.baseUrl, required this.client});

  @override
  Future<PatientModel> getPatientData(String authId) async {
    final response = await client.get(Uri.parse('$baseUrl/patient/$authId'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return PatientModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      throw NotFoundException('Paciente no encontrado');
    } else {
      throw FetchDataException('Error al obtener datos del paciente');
    }
  }

  @override
  Future<PsychologistModel> getPsychologistData(String authId) async {
    final response = await client.get(Uri.parse('$baseUrl/psychologist/$authId'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return PsychologistModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      throw NotFoundException('Psicólogo no encontrado');
    } else {
      throw FetchDataException('Error al obtener datos del psicólogo');
    }
  }

  @override
  Future<PatientModel> createPatient({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    String? dateOfBirth,
    required String idToken,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/patient'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
      body: json.encode({
        'authId': uid,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth,
      }),
    );

    if (response.statusCode == 201) {
      final jsonData = json.decode(response.body);
      return PatientModel.fromJson(jsonData);
    } else {
      throw CreateDataException('Error al crear paciente');
    }
  }

  @override
  Future<PsychologistModel> createPsychologist({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required String professionalLicense,
    String? specialty,
    String? schedule,
    String? aboutMe,
    required String dateOfBirth,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/psychologist'),
      headers: {'Content-Type': 'application/json',},
      body: json.encode({
        'authId': uid,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'professionalLicense': professionalLicense,
        'specialty': specialty,
        'schedule': schedule,
        'aboutMe': aboutMe,
        'dateOfBirth': dateOfBirth,
      }),
    );

    if (response.statusCode == 201) {
      final jsonData = json.decode(response.body);
      return PsychologistModel.fromJson(jsonData);
    } else {
      throw CreateDataException('Error al crear psicólogo');
    }
  }

  @override
  Future<UserEntity> getUserData(String authId) async {
    try {
      return await getPatientData(authId);
    } on NotFoundException {
      try {
        return await getPsychologistData(authId);
      } on NotFoundException {
        throw NotFoundException('Usuario no encontrado');
      }
    } catch (e) {
      rethrow;
    }
  }
}
