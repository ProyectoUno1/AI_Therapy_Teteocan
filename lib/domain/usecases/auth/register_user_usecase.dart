import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';

class RegisterUserUseCase {
  final AuthRepository repository;

  RegisterUserUseCase(this.repository);

  Future<UserEntity> registerPatient({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required DateTime dateOfBirth,

  }) {
    return repository.registerPatient(
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
    );
  }

  Future<UserEntity> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalLicense, // antes era professionalId
    String? specialty,
    String? schedule,
    String? aboutMe,
    required DateTime dateOfBirth,
  }) {
    return repository.registerPsychologist(
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
      professionalLicense: professionalLicense, // esto se llama professionalId en la interfaz
      specialty: specialty,
      schedule: schedule,
      aboutMe: aboutMe,
      dateOfBirth: dateOfBirth,
    );
  }
}
