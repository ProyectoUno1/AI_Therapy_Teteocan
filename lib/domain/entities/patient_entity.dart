import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

class PatientEntity extends UserEntity {
  final String? dateOfBirth;
  final String? gender;

  const PatientEntity({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    String? profilePictureUrl,
    this.dateOfBirth,
    this.gender,
  }) : super(
          uid: uid,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          role: 'paciente',
          profilePictureUrl: profilePictureUrl,
        );

  @override
  List<Object?> get props => [...super.props, dateOfBirth, gender];
}
