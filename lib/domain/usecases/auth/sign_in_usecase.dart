import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  Future<dynamic> call({
    required String email,
    required String password,
  }) async {
    
    return await _authRepository.signIn(
      email: email,
      password: password,
    );
  }
}