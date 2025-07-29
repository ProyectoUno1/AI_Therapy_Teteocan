// lib/data/repositories/auth_repository_impl.dart

import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.userRemoteDataSource,
  });

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    print('🚀 Repo: Iniciando sesión para $email');
    try {
      await authRemoteDataSource.signIn(
        email: email,
        password: password,
      );
      print('✅ Repo: Inicio de sesión en Firebase exitoso.');
    } on FirebaseAuthException catch (e) {
      print('❌ Repo: FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw UserNotFoundException('No se encontró un usuario con ese email.');
      } else if (e.code == 'wrong-password') {
        throw WrongPasswordException('La contraseña es incorrecta.');
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailException('El formato del email es incorrecto.');
      } else if (e.code == 'invalid-credential') {
        throw InvalidCredentialsException('Credenciales inválidas. Verifica tu email y contraseña.');
      }
    
      throw AuthException('Error de autenticación: ${e.message ?? e.code}');
    } on AppException {
      rethrow; 
    } catch (e) {
      print('❌ Repo: Error genérico al iniciar sesión: $e');
      throw FetchDataException(
        'Error inesperado en la capa de repositorio al iniciar sesión: $e',
      );
    }
  }

  @override
  Future<PatientModel> registerPatient({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required DateTime dateOfBirth,
    
  }) async {
    try {
      final now = DateTime.now();

      final userCredential = await authRemoteDataSource.register(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw UserCreationException(
          'No se pudo crear el usuario de autenticación para el paciente.',
        );
      }

      final patient = PatientModel(
        uid: userCredential.user!.uid,
        email: email,
        username: username,
        
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        createdAt: now,
        updatedAt: now,
      );

      await userRemoteDataSource.createPatient(
        uid: patient.uid,
        username: patient.username,
        email: patient.email,
        
        phoneNumber: patient.phoneNumber,
        dateOfBirth: patient.dateOfBirth,
        profilePictureUrl: patient.profilePictureUrl,
      );
      print('✅ Repo: Registro de paciente y datos de Firestore exitoso.');
      return patient; 
    } on FirebaseAuthException catch (e) {
      print('❌ Repo: FirebaseAuthException en registro de paciente: ${e.code} - ${e.message}');
       if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException('El email ya está en uso.');
      } else if (e.code == 'weak-password') {
        throw WeakPasswordException('La contraseña es demasiado débil.');
      }
      throw AuthException('Error de autenticación al registrar paciente: ${e.message ?? e.code}');
    } on AppException {
      rethrow;
    } catch (e) {
      print('🚨 ERROR CAPTURADO en AuthRepositoryImpl.registerPatient: $e');
      throw FetchDataException('Error inesperado al registrar paciente: $e');
    }
  }

  @override
  Future<PsychologistModel> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalLicense,
    required DateTime dateOfBirth,
  }) async {
    try {
      final now = DateTime.now();

      final userCredential = await authRemoteDataSource.register(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw UserCreationException(
          'No se pudo crear el usuario de autenticación para el psicólogo.',
        );
      }

      final psychologist = PsychologistModel(
        uid: userCredential.user!.uid,
        email: email,
        username: username,
        
        phoneNumber: phoneNumber,
        professionalLicense: professionalLicense,
        dateOfBirth: dateOfBirth,
        createdAt: now,
        updatedAt: now,
      );

      await userRemoteDataSource.createPsychologist(
        uid: psychologist.uid,
        username: psychologist.username,
        email: psychologist.email,
       
        phoneNumber: psychologist.phoneNumber,
        professionalLicense: psychologist.professionalLicense,
        dateOfBirth: psychologist.dateOfBirth,
        profilePictureUrl: psychologist.profilePictureUrl,
      );
      print('✅ Repo: Registro de psicólogo y datos de Firestore exitoso.');
      return psychologist;  
    } on FirebaseAuthException catch (e) {
      print('❌ Repo: FirebaseAuthException en registro de psicólogo: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException('El email ya está en uso.');
      } else if (e.code == 'weak-password') {
        throw WeakPasswordException('La contraseña es demasiado débil.');
      }
      throw AuthException('Error de autenticación al registrar psicólogo: ${e.message ?? e.code}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Error inesperado al registrar psicólogo: $e');
    }
  }

  @override
  Future<void> signOut() async {
    print('🔴 ¡ALERT! Se llamó a signOut() desde AuthRepositoryImpl.');
    StackTrace.current.toString().split('\n').forEach((line) {
      if (line.contains('package:ai_therapy_teteocan')) {
        print(line);
      }
    });
    try {
      await authRemoteDataSource.signOut();
      print('✅ Sesión cerrada exitosamente en Firebase.');
    } on FirebaseAuthException catch (e) {
      print('❌ Repo: FirebaseAuthException al cerrar sesión: ${e.code} - ${e.message}');
      throw AuthException('Error de autenticación al cerrar sesión: ${e.message ?? e.code}');
    } on AppException {
      rethrow;
    } catch (e) {
      print('❌ Repo: Error genérico al cerrar sesión: $e');
      throw AuthException('Error inesperado al cerrar sesión: $e');
    }
  }

  @override
  Stream<dynamic?> get authStateChanges {
    return authRemoteDataSource.authStateChanges.asyncMap((fbUser) async {
      print('DEBUG: Repo authStateChanges - Firebase User: ${fbUser?.uid ?? 'null'}');
      if (fbUser == null) {
        print('DEBUG: Repo authStateChanges - Firebase User es null. Emitiendo null.');
        return null; 
      }
      try {
        
        final userModel = await userRemoteDataSource.getUserData(fbUser.uid);
        if (userModel != null) {
          print('✅ DEBUG: Repo authStateChanges - Perfil de usuario (tipo: ${userModel.runtimeType}) cargado para UID: ${fbUser.uid}');
          return userModel;
        } else {
          print('🔴 DEBUG: Repo authStateChanges - Usuario Firebase ${fbUser.uid} autenticado, pero NO se encontró perfil de Patient/Psychologist.');
          return null;
        }
      } on AppException catch (e) {
        print('🔴 Error al obtener datos de usuario para authStateChanges (AppException): $e');
        return null;
      } catch (e) {
        print('🔴 Error inesperado al obtener datos de usuario para authStateChanges: $e');
        return null;
      }
    });
  }
}