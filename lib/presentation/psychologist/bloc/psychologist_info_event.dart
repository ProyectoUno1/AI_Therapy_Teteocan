// lib/presentation/psychologist/bloc/psychologist_info_event.dart

import 'package:equatable/equatable.dart';

abstract class PsychologistInfoEvent extends Equatable {
  const PsychologistInfoEvent();

  @override
  List<Object?> get props => [];
}

class LoadPsychologistInfoEvent extends PsychologistInfoEvent {
  final String uid;

  const LoadPsychologistInfoEvent({required this.uid});

  @override
  List<Object?> get props => [uid];
}

class PsychologistProfilePictureUploadRequested extends PsychologistInfoEvent {
  final String imagePath;
  PsychologistProfilePictureUploadRequested(this.imagePath);
}

class SetupProfessionalInfoEvent extends PsychologistInfoEvent {
  final String uid;
  final String fullName;
  final String professionalTitle;
  final String licenseNumber;
  final int yearsExperience;
  final String description;
  final List<String> education;
  final List<String> certifications;
  final String email;
  final String? profilePictureUrl;
  final String? selectedSpecialty;
  final List<String> selectedSubSpecialties;
  final Map<String, dynamic> schedule;
  final bool isAvailable;
  final double? price;

  const SetupProfessionalInfoEvent({
    required this.uid,
    required this.fullName,
    required this.professionalTitle,
    required this.licenseNumber,
    required this.yearsExperience,
    required this.description,
    required this.education,
    required this.certifications,
    required this.email,
    this.profilePictureUrl,
    this.selectedSpecialty,
    required this.selectedSubSpecialties,
    required this.schedule,
    required this.isAvailable,
    this.price,
  });

  @override
  List<Object?> get props => [
        uid,
        fullName,
        professionalTitle,
        licenseNumber,
        yearsExperience,
        description,
        education,
        certifications,
        profilePictureUrl,
        email,
        selectedSpecialty,
        selectedSubSpecialties,
        schedule,
        isAvailable,
        price,
      ];
}