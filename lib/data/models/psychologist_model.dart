// lib/data/models/psychologist_model.dart
import 'package:ai_therapy_teteocan/data/models/user_model.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';

class PsychologistModel extends UserModel {
  final String professionalId;
  final String? specialty;
  final String? schedule;
  final String? aboutMe;

  const PsychologistModel({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required this.professionalId,
    this.specialty,
    this.schedule,
    this.aboutMe,
    String? profilePictureUrl,
  }) : super(
         uid: uid,
         username: username,
         email: email,
         phoneNumber: phoneNumber,
         role: 'psicologo',
         professionalId: professionalId,
         profilePictureUrl: profilePictureUrl,
       );

  factory PsychologistModel.fromJson(Map<String, dynamic> json) {
    return PsychologistModel(
      uid: json['firebaseUid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      professionalId: json['professionalId'] as String,
      specialty: json['specialty'] as String?,
      schedule: json['schedule'] as String?,
      aboutMe: json['aboutMe'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = super.toJson();
    json['professionalId'] = professionalId;
    json['specialty'] = specialty;
    json['schedule'] = schedule;
    json['aboutMe'] = aboutMe;
    return json;
  }

  factory PsychologistModel.fromEntity(PsychologistEntity entity) {
    return PsychologistModel(
      uid: entity.uid,
      username: entity.username,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      professionalId: entity.professionalId,
      specialty: entity.specialty,
      schedule: entity.schedule,
      aboutMe: entity.aboutMe,
      profilePictureUrl: entity.profilePictureUrl,
    );
  }
}
