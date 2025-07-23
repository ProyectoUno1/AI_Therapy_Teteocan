// lib/domain/entities/psychologist_entity.dart
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

class PsychologistEntity extends UserEntity {
  final String professionalId;
  final String? specialty;
  final String? schedule;
  final String? aboutMe;

  const PsychologistEntity({
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

  @override
  List<Object?> get props => [
    ...super.props,
    professionalId,
    specialty,
    schedule,
    aboutMe,
  ];
}
