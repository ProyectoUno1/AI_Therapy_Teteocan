import 'package:ai_therapy_teteocan/data/models/user_model.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';

class PsychologistModel extends UserModel {
  final String professionalLicense; // renombrado a professionalLicense
  final String? specialty;
  final String? schedule;
  final String? aboutMe;

  const PsychologistModel({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required this.professionalLicense,
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
          professionalId: professionalLicense,
          profilePictureUrl: profilePictureUrl,
        );

  factory PsychologistModel.fromJson(Map<String, dynamic> json) {
    return PsychologistModel(
      uid: json['firebaseUid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      professionalLicense: json['professional_license'] as String,  // snake_case
      specialty: json['specialty'] as String?,
      schedule: json['schedule'] as String?,
      aboutMe: json['about_me'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['professional_license'] = professionalLicense;
    json['specialty'] = specialty;
    json['schedule'] = schedule;
    json['about_me'] = aboutMe;
    return json;
  }

  factory PsychologistModel.fromEntity(PsychologistEntity entity) {
    return PsychologistModel(
      uid: entity.uid,
      username: entity.username,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      professionalLicense: entity.professionalId,
      specialty: entity.specialty,
      schedule: entity.schedule,
      aboutMe: entity.aboutMe,
      profilePictureUrl: entity.profilePictureUrl,
    );
  }
}

/// Modelo para representar un paciente en el contexto del psicólogo
class PsychologistPatient {
  final String id;
  final String name;
  final String? imageUrl;
  final String latestMessage;
  final String lastSeen;
  final bool isOnline;

  const PsychologistPatient({
    required this.id,
    required this.name,
    this.imageUrl,
    this.latestMessage = '',
    this.lastSeen = '',
    this.isOnline = false,
  });
}

/// Modelo para representar una sesión con un paciente
class Session {
  final String id;
  final DateTime time;
  final PsychologistPatient patient;
  final String type;
  final int durationMinutes;

  Session({
    required this.id,
    required this.time,
    required this.patient,
    required this.type,
    required this.durationMinutes,
  });
}

/// Modelo resumen de artículo para psicólogos
class PsychologistArticleSummary {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime date;

  PsychologistArticleSummary({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
  });
}
