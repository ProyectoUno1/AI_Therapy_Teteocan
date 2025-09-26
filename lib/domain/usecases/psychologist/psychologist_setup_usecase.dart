// lib/domain/usecases/psychologist/psychologist_setup_usecase.dart

import 'package:ai_therapy_teteocan/domain/repositories/psychologist_repository.dart';
import 'package:flutter/foundation.dart';

class PsychologistSetupUseCase {
  final PsychologistRepository _repository;

  PsychologistSetupUseCase(this._repository);

  Future<void> call({
    required String uid,
    required String username,
    required String email,
    required String professionalTitle,
    required String licenseNumber,
    required int yearsExperience,
    required String description,
    required List<String> education,
    required List<String> certifications,
    required String? profilePictureUrl,
    required String? selectedSpecialty,
    required List<String>? selectedSubSpecialties,
    required Map<String, dynamic>? schedule,
    required bool? isAvailable,
  }) async {
    try {
      await _repository.updateProfessionalInfo(
        uid: uid,
        username: username,
        professionalTitle: professionalTitle,
        professionalLicense: licenseNumber,
        yearsExperience: yearsExperience,
        description: description,
        education: education,
        certifications: certifications,
        specialty: selectedSpecialty,
        subSpecialties: selectedSubSpecialties,
        schedule: schedule,
        profilePictureUrl: profilePictureUrl,
        isAvailable: isAvailable,
      );
    } catch (e) {
      rethrow;
    }
  }
}
