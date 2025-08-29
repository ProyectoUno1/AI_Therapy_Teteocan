import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';


class PatientEntity extends UserEntity {
  final String? dateOfBirth;
  

  const PatientEntity({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    String? profilePictureUrl,
    this.dateOfBirth,
  }) : super(
          uid: uid,
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          role: 'paciente',
          profilePictureUrl: profilePictureUrl,
        );

  @override
  List<Object?> get props => [...super.props, dateOfBirth];
}
