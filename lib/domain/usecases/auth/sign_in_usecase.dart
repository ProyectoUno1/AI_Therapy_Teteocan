// lib/domain/usecases/auth/sign_in_usecase.dart
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<UserEntity> call({required String email, required String password}) {
    return repository.signIn(email: email, password: password);
  }
}
