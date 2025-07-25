import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

class PsychologistEntity extends UserEntity {
  final String professionalId;
  final String? specialty;
  final String? schedule;
  final String? aboutMe;
  final String? gender;
  final String? dateOfBirth;

  const PsychologistEntity({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required this.professionalId,
    this.specialty,
    this.schedule,
    this.aboutMe,
    this.gender,
    this.dateOfBirth,
    String? profilePictureUrl,
  }) : super(
          uid: uid,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          role: 'psicologo',
          profilePictureUrl: profilePictureUrl,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        professionalId,
        specialty,
        schedule,
        aboutMe,
        gender,
        dateOfBirth,
      ];
}
