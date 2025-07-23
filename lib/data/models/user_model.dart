// lib/data/models/user_model.dart
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required String role,
    String? professionalId,
    String? profilePictureUrl,
  }) : super(
         uid: uid,
         username: username,
         email: email,
         phoneNumber: phoneNumber,
         role: role,
         professionalId: professionalId,
         profilePictureUrl: profilePictureUrl,
       );

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

  // Convertir de UserEntity a UserModel (útil si recibes una entidad y necesitas un modelo para JSON)
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
