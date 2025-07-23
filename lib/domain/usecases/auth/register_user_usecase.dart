// lib/domain/usecases/auth/register_user_usecase.dart
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
  }) {
    return repository.registerPatient(
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
    );
  }

  Future<UserEntity> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalId,
  }) {
    return repository.registerPsychologist(
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
      professionalId: professionalId,
    );
  }
}
