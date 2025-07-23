// lib/domain/repositories/auth_repository.dart
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn({required String email, required String password});
  Future<UserEntity> registerPatient({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
  });
  Future<UserEntity> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalId,
  });
  Future<void> signOut();
  Stream<UserEntity?>
  get authStateChanges; // Para escuchar cambios de autenticación
}
