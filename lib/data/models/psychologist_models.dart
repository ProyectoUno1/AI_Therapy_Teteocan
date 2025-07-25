// lib/data/models/psychologist_model.dart
import 'package:ai_therapy_teteocan/data/models/user_model.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';
import 'package:equatable/equatable.dart';

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

// NUEVAS CLASES PARA LA VISTA DEL HOME DEL PSICÓLOGO (Añadidas aquí)

// Represents a patient for the psychologist's view (simplified)
class PsychologistPatient extends Equatable {
  final String id;
  final String name;
  final String? imageUrl; // Optional image
  final String latestMessage; // For recent chats
  final String lastSeen; // For recent chats time
  final bool isOnline; // For recent chats dot

  const PsychologistPatient({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.latestMessage,
    required this.lastSeen,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [id, name, imageUrl, latestMessage, lastSeen, isOnline];
}

// Represents a therapy session for today's summary
class Session extends Equatable {
  final String id;
  final DateTime time;
  final PsychologistPatient patient;
  final String type; // e.g., "Therapy Session", "Initial Consultation", "Follow-up"
  final int durationMinutes;

  const Session({
    required this.id,
    required this.time,
    required this.patient,
    required this.type,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [id, time, patient, type, durationMinutes];
}

// Represents an article summary for 'Your Articles'
class PsychologistArticleSummary extends Equatable {
  final String id;
  final String title;
  final String imageUrl; // Image for the article card
  final DateTime date; // Publish date

  const PsychologistArticleSummary({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
  });

  @override
  List<Object?> get props => [id, title, imageUrl, date];
}