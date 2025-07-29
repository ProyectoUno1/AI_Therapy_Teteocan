import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart'; // O el tipo base de usuario que manejes
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

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