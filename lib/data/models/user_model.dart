// lib/data/models/user_model.dart
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.username,
    required super.email,
    required super.phoneNumber,
    required super.role,
    super.professionalId,
    super.profilePictureUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['firebaseUid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: json['role'] as String,
      professionalId: json['professionalId'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firebaseUid': uid,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      if (professionalId != null) 'professionalId': professionalId,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      username: entity.username,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      role: entity.role,
      professionalId: entity.professionalId,
      profilePictureUrl: entity.profilePictureUrl,
    );
  }
}
