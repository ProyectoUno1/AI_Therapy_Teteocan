// lib/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String username;
  final String email;
  final String phoneNumber;
  final String role; // 'paciente' o 'psicologo'
  final String? professionalId; // Solo para psicólogos
  final String? profilePictureUrl; // Si planeas añadir fotos de perfil

  const UserEntity({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.professionalId,
    this.profilePictureUrl,
  });

  @override
  List<Object?> get props => [
    uid,
    username,
    email,
    phoneNumber,
    role,
    professionalId,
    profilePictureUrl,
  ];
}
