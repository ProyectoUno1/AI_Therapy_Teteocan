// lib/data/repositories/psychologist_repository_impl.dart

import 'package:ai_therapy_teteocan/data/datasources/psychologist_remote_datasource.dart';
import 'package:ai_therapy_teteocan/domain/repositories/psychologist_repository.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart'; 

class PsychologistRepositoryImpl implements PsychologistRepository {
  final PsychologistRemoteDataSource _remoteDataSource;

  PsychologistRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> updateBasicInfo({
    required String uid,
    String? username,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    await _remoteDataSource.updateBasicInfo(
      uid: uid,
      username: username,
      phoneNumber: phoneNumber,
      profilePictureUrl: profilePictureUrl,
    );
  }

  @override
  Future<void> updateProfessionalInfo({
    required String uid,
    String? fullName,
    String? professionalLicense,
    String? professionalTitle,
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
    await _remoteDataSource.updateProfessionalInfo(
      uid: uid,
      fullName: fullName,
      professionalLicense: professionalLicense,
      professionalTitle: professionalTitle,
      yearsExperience: yearsExperience,
      description: description,
      education: education,
      certifications: certifications,
      specialty: specialty,
      subSpecialties: subSpecialties,
      schedule: schedule,
      profilePictureUrl: profilePictureUrl,
      isAvailable: isAvailable,
    );
  }

  @override
  Future<PsychologistModel?> getPsychologistInfo(String uid) async {
    try {
      final psychologist = await _remoteDataSource.getPsychologistInfo(uid);
      return psychologist;
    } catch (e) {
      // Manejo de errores
      print('Error al obtener la información del psicólogo: $e');
      return null;
    }
  }
}