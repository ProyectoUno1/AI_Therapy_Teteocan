// lib/domain/repositories/psychologist_repository.dart

import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

abstract class PsychologistRepository {

  Future<void> updateBasicInfo({
    required String uid,
    String? username,
    String? phoneNumber,
    String? profilePictureUrl,
  });


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
  });


  Future<String> uploadProfilePicture(String imagePath);

  Future<PsychologistModel?> getPsychologistInfo(String uid);




}