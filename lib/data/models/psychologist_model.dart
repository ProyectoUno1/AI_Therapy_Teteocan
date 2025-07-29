// lib/data/models/psychologist_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';


class PsychologistModel {
  final String uid; // Este será el ID del documento en Firestore (firebase_uid)
  final String username; // Corresponde al campo 'full_name' en Firestore
  final String email; // Corresponde al campo 'email' en Firestore
  final String phoneNumber; // Corresponde al campo 'phone_number' en Firestore
  final String professionalLicense; // Corresponde al campo 'professional_license' en Firestore
  final String? profilePictureUrl; // Corresponde al campo 'profile_picture_url' en Firestore
  final DateTime dateOfBirth; // Corresponde al campo 'date_of_birth' en Firestore (String "YYYY-MM-DD")
  final DateTime createdAt;   // Corresponde al campo 'created_at' en Firestore (Timestamp)
  final DateTime updatedAt;   // Corresponde al campo 'updated_at' en Firestore (Timestamp)

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
  });

  
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
        : Timestamp.now(); // Fallback por si acaso
    final Timestamp updatedAtTimestamp = data['updated_at'] is Timestamp
        ? data['updated_at']
        : Timestamp.now(); // Fallback por si acaso

    
    DateTime parsedDateOfBirth;
    if (data['date_of_birth'] is Timestamp) {
      parsedDateOfBirth = (data['date_of_birth'] as Timestamp).toDate();
    } else if (data['date_of_birth'] is String) {
      parsedDateOfBirth = DateTime.tryParse(data['date_of_birth']) ?? DateTime(1900); 
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
    );
  }

  
  Map<String, dynamic> toFirestore() {
    return {
      "username": username,
      "email": email,
      "phone_number": phoneNumber,
      "professional_license": professionalLicense,
      "profile_picture_url": profilePictureUrl,
      "date_of_birth": dateOfBirth.toIso8601String().split('T')[0], // Almacenar solo la fecha como String "YYYY-MM-DD"
      "created_at": Timestamp.fromDate(createdAt), // Guardar como Timestamp de Firestore
      "updated_at": Timestamp.fromDate(updatedAt), // Guardar como Timestamp de Firestore
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
    };
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
