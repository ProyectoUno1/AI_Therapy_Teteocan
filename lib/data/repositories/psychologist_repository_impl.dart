// lib/data/repositories/psychologist_repository_impl.dart

import 'package:ai_therapy_teteocan/data/datasources/psychologist_remote_datasource.dart';
import 'package:ai_therapy_teteocan/domain/repositories/psychologist_repository.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

class PsychologistRepositoryImpl implements PsychologistRepository {
  final PsychologistRemoteDataSource _remoteDataSource;

  PsychologistRepositoryImpl(this._remoteDataSource);

  // INFORMACIÓN BÁSICA

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


  // INFORMACIÓN PROFESIONAL

  @override
  Future<void> updateProfessionalInfo({
    required String uid,
    String? username,
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
    double? price,
  }) async {
    await _remoteDataSource.updateProfessionalInfo(
      uid: uid,
      fullName: username,
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
      price: price,
    );
  }

  // OBTENER INFORMACIÓN

  @override
  Future<PsychologistModel?> getPsychologistInfo(String uid) async {
    try {
      return await _remoteDataSource.getPsychologistInfo(uid);
    } catch (e) {
      return null;
    }
  }

  // SUBIDA DE IMAGEN
  @override
  Future<String> uploadProfilePicture(String imagePath) {
    return _remoteDataSource.uploadProfilePicture(imagePath);
  }

 
}