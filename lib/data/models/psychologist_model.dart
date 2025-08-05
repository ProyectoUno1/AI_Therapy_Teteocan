// lib/data/models/psychologist_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PsychologistModel {
  final String uid;
  final String username;
  final String email;
  final String phoneNumber;
  final String professionalLicense;
  final String? profilePictureUrl;
  final DateTime dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role;

  // Nuevos campos para funcionalidad de psicólogos
  final String? specialty;
  final double? rating;
  final bool isAvailable;
  final String? description;
  final double? hourlyRate;
  final String? schedule;

  const PsychologistModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.professionalLicense,
    this.profilePictureUrl,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    this.role = 'psychologist',
    this.specialty,
    this.rating,
    this.isAvailable = false,
    this.description,
    this.hourlyRate,
    this.schedule,
  });

  // Constructor conveniente para crear datos de ejemplo
  PsychologistModel.example({
    required String id,
    required this.username,
    required this.email,
    this.specialty,
    this.rating,
    this.isAvailable = false,
    this.profilePictureUrl,
    this.description,
    this.hourlyRate,
    this.schedule,
  }) : uid = id,
       phoneNumber = '',
       professionalLicense = '',
       dateOfBirth = DateTime(1990, 1, 1),
       createdAt = DateTime(2024, 1, 1),
       updatedAt = DateTime(2024, 1, 1),
       role = 'psychologist';

  factory PsychologistModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('El documento de psicólogo no contiene datos.');
    }

    // Manejo robusto de Timestamps para createdAt y updatedAt
    final Timestamp createdAtTimestamp = data['created_at'] is Timestamp
        ? data['created_at']
        : Timestamp.now();
    final Timestamp updatedAtTimestamp = data['updated_at'] is Timestamp
        ? data['updated_at']
        : Timestamp.now();

    DateTime parsedDateOfBirth;
    if (data['date_of_birth'] is Timestamp) {
      parsedDateOfBirth = (data['date_of_birth'] as Timestamp).toDate();
    } else if (data['date_of_birth'] is String) {
      parsedDateOfBirth =
          DateTime.tryParse(data['date_of_birth']) ?? DateTime(1900);
    } else {
      parsedDateOfBirth = DateTime(1900);
    }

    return PsychologistModel(
      uid: snapshot.id,
      username: data['username'] as String,
      email: data['email'] as String,
      phoneNumber: data['phone_number'] as String,
      professionalLicense: data['professional_license'] as String,
      profilePictureUrl: data['profile_picture_url'] as String?,
      dateOfBirth: parsedDateOfBirth,
      createdAt: createdAtTimestamp.toDate(),
      updatedAt: updatedAtTimestamp.toDate(),
      role: data['role'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "username": username,
      "email": email,
      "phone_number": phoneNumber,
      "professional_license": professionalLicense,
      "profile_picture_url": profilePictureUrl,
      "date_of_birth": dateOfBirth.toIso8601String().split('T')[0],
      "created_at": Timestamp.fromDate(createdAt),
      "updated_at": Timestamp.fromDate(updatedAt),
      "role": role,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'professionalLicense': professionalLicense,
      'profilePictureUrl': profilePictureUrl,
      'dateOfBirth': dateOfBirth.toIso8601String().split('T')[0],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'role': ['role'] as String? ?? 'psychologist',
    };
  }
}

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
