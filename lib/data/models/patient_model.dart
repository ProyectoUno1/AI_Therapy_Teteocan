// lib/data/models/patient_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; 
 import 'package:ai_therapy_teteocan/domain/entities/patient_entity.dart';
 

class PatientModel{
  final String uid; 
  final String username; 
  final String email; 
  final String phoneNumber; 
  final String? profilePictureUrl; 
  final DateTime dateOfBirth; 
  final DateTime createdAt; 
  final DateTime updatedAt; 

  const PatientModel({
    required this.uid,
    required this.username, 
    required this.email,
    required this.phoneNumber,
    this.profilePictureUrl,
    required this.dateOfBirth, 
    required this.createdAt,
    required this.updatedAt,
  });

  
  factory PatientModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('El documento de paciente no contiene datos.');
    }

  
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
      parsedDateOfBirth = DateTime.tryParse(data['date_of_birth']) ?? DateTime(1900); 
    } else {
      parsedDateOfBirth = DateTime(1900); 
    }

    return PatientModel(
      uid: snapshot.id, 
      username: data['username'] as String,
      email: data['email'] as String,
      phoneNumber: data['phone_number'] as String, 
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
      "profile_picture_url": profilePictureUrl,
      "date_of_birth": dateOfBirth.toIso8601String().split('T')[0], 
      "created_at": Timestamp.fromDate(createdAt), 
      "updated_at": Timestamp.fromDate(updatedAt), 
    };
  }

  
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'dateOfBirth': dateOfBirth.toIso8601String().split('T')[0],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

 
  factory PatientModel.fromEntity(PatientEntity entity) {
    return PatientModel(
      uid: entity.uid,
      username: entity.username, 
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      profilePictureUrl: entity.profilePictureUrl,
     
      dateOfBirth: (entity as dynamic).dateOfBirth is DateTime
          ? (entity as dynamic).dateOfBirth
          : DateTime(1900), 
      createdAt: DateTime.now(), 
      updatedAt: DateTime.now(), 
    );
  }
}