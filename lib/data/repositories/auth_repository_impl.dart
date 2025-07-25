import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
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
      final userModel = await userRemoteDataSource.getUserData(
        userCredential.user!.uid,
      );
      return userModel;
    } on AppException {
      rethrow;
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
    required DateTime dateOfBirth,
  }) async {
    try {
      final userCredential = await authRemoteDataSource.register(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw AppException('No se pudo registrar el usuario en Firebase.');
      }

      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        throw AppException('No se pudo obtener el token de autenticación.');
      }

      final userModel = await userRemoteDataSource.createPatient(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth.toIso8601String(),
        idToken: idToken,
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
    required String professionalLicense,
    String? specialty,
    String? schedule,
    String? aboutMe,
    required DateTime dateOfBirth,
  }) async {
    try {
      final userCredential = await authRemoteDataSource.register(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw AppException('No se pudo registrar el usuario en Firebase.');
      }

      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        throw AppException('No se pudo obtener el token de autenticación.');
      }

      final userModel = await userRemoteDataSource.createPsychologist(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        professionalLicense: professionalLicense,
        specialty: specialty,
        schedule: schedule,
        dateOfBirth: dateOfBirth.toIso8601String(),
        aboutMe: aboutMe,
        
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
      try {
        final userModel = await userRemoteDataSource.getUserData(fbUser.uid);
        return userModel;
      } on AppException catch (e) {
        print('Error al obtener datos de usuario para authStateChanges: $e');
        return null;
      }
    });
  }
}
