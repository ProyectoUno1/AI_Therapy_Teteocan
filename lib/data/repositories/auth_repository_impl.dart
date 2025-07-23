// lib/data/repositories/auth_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/models/user_model.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.userRemoteDataSource,
  });

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await authRemoteDataSource.signIn(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw UserNotFoundException(
          'No se pudo obtener el usuario después del inicio de sesión.',
        );
      }
      // Obtener los datos completos del usuario y su rol desde tu backend
      final userModel = await userRemoteDataSource.getUserData(
        userCredential.user!.uid,
      );
      return userModel;
    } on AppException {
      rethrow; // Relanzar excepciones personalizadas
    } catch (e) {
      throw FetchDataException('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<UserEntity> registerPatient({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
  }) async {
    try {
      final userCredential = await authRemoteDataSource.register(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw AppException('No se pudo registrar el usuario en Firebase.');
      }
      // Crear el usuario en tu backend con el rol de paciente
      final userModel = await userRemoteDataSource.createUser(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        role: 'paciente',
      );
      return userModel;
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Error al registrar paciente: $e');
    }
  }

  @override
  Future<UserEntity> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalId,
  }) async {
    try {
      final userCredential = await authRemoteDataSource.register(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw AppException('No se pudo registrar el usuario en Firebase.');
      }
      // Crear el usuario en tu backend con el rol de psicólogo
      final userModel = await userRemoteDataSource.createUser(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        role: 'psicologo',
        professionalId: professionalId,
      );
      return userModel;
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Error al registrar psicólogo: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await authRemoteDataSource.signOut();
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Error al cerrar sesión: $e');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return authRemoteDataSource.authStateChanges.asyncMap((fbUser) async {
      if (fbUser == null) {
        return null;
      }
      // Si hay un usuario de Firebase, obtener sus datos completos y rol de tu backend
      try {
        final userModel = await userRemoteDataSource.getUserData(fbUser.uid);
        return userModel;
      } on AppException catch (e) {
        print('Error al obtener datos de usuario para authStateChanges: $e');
        // Si no se encuentra el usuario en tu backend, podría ser un usuario recién autenticado
        // o un problema. Podrías decidir cerrar sesión o devolver un UserEntity parcial.
        // Por ahora, devolvemos null si no se encuentran los datos en el backend.
        return null;
      }
    });
  }
}
