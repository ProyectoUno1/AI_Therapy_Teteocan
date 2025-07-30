// lib/data/repositories/auth_repository_impl.dart

import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; 

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;
  final FirebaseAuth _firebaseAuth;

  // Constructor
  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.userRemoteDataSource,
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<void> signIn({required String email, required String password}) async {
    log('🚀 Repo: Iniciando sesión para $email', name: 'AuthRepositoryImpl');
    try {
      await authRemoteDataSource.signIn(email: email, password: password);
      log(
        '✅ Repo: Inicio de sesión en Firebase exitoso.',
        name: 'AuthRepositoryImpl',
      );
    } on FirebaseAuthException catch (e) {
      log(
        '❌ Repo: FirebaseAuthException: ${e.code} - ${e.message}',
        name: 'AuthRepositoryImpl',
      );
      if (e.code == 'user-not-found') {
        throw UserNotFoundException('No se encontró un usuario con ese email.');
      } else if (e.code == 'wrong-password') {
        throw WrongPasswordException('La contraseña es incorrecta.');
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailException('El formato del email es incorrecto.');
      } else if (e.code == 'invalid-credential') {
        throw InvalidCredentialsException(
          'Credenciales inválidas. Verifica tu email y contraseña.',
        );
      }
      throw AuthException('Error de autenticación: ${e.message ?? e.code}');
    } on AppException {
      rethrow;
    } catch (e) {
      log(
        '❌ Repo: Error genérico al iniciar sesión: $e',
        name: 'AuthRepositoryImpl',
      );
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
    log(
      '🚀 Repo: Iniciando registro de paciente para $email',
      name: 'AuthRepositoryImpl',
    );
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
        role: 'patient', 
      );

      await userRemoteDataSource.createPatient(
        uid: patient.uid,
        username: patient.username,
        email: patient.email,
        phoneNumber: patient.phoneNumber,
        dateOfBirth: patient.dateOfBirth,
        profilePictureUrl: patient.profilePictureUrl,
        role: patient.role,

        
      );
      log(
        '✅ Repo: Registro de paciente y datos de Firestore exitoso.',
        name: 'AuthRepositoryImpl',
      );

    
      await signOut(); 
      log(
        '✅ Repo: Usuario desautenticado después del registro de paciente.',
        name: 'AuthRepositoryImpl',
      );

      return patient;
    } on FirebaseAuthException catch (e) {
      log(
        '❌ Repo: FirebaseAuthException en registro de paciente: ${e.code} - ${e.message}',
        name: 'AuthRepositoryImpl',
      );
      if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException('El email ya está en uso.');
      } else if (e.code == 'weak-password') {
        throw WeakPasswordException('La contraseña es demasiado débil.');
      }
      throw AuthException(
        'Error de autenticación al registrar paciente: ${e.message ?? e.code}',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      log(
        '🚨 ERROR CAPTURADO en AuthRepositoryImpl.registerPatient: $e',
        name: 'AuthRepositoryImpl',
      );
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
    log(
      '🚀 Repo: Iniciando registro de psicólogo para $email',
      name: 'AuthRepositoryImpl',
    );
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
        role: 'psychologist',
      );

      await userRemoteDataSource.createPsychologist(
        uid: psychologist.uid,
        username: psychologist.username,
        email: psychologist.email,
        phoneNumber: psychologist.phoneNumber,
        professionalLicense: psychologist.professionalLicense,
        dateOfBirth: psychologist.dateOfBirth,
        profilePictureUrl: psychologist.profilePictureUrl,
        role: psychologist.role,

        
      );
      log(
        '✅ Repo: Registro de psicólogo y datos de Firestore exitoso.',
        name: 'AuthRepositoryImpl',
      );

      
      await signOut(); 
      log(
        '✅ Repo: Usuario desautenticado después del registro de psicólogo.',
        name: 'AuthRepositoryImpl',
      );

      return psychologist; 
    } on FirebaseAuthException catch (e) {
      log(
        '❌ Repo: FirebaseAuthException en registro de psicólogo: ${e.code} - ${e.message}',
        name: 'AuthRepositoryImpl',
      );
      if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseException('El email ya está en uso.');
      } else if (e.code == 'weak-password') {
        throw WeakPasswordException('La contraseña es demasiado débil.');
      }
      throw AuthException(
        'Error de autenticación al registrar psicólogo: ${e.message ?? e.code}',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      log(
        '🚨 ERROR CAPTURADO en AuthRepositoryImpl.registerPsychologist: $e',
        name: 'AuthRepositoryImpl',
      );
      throw FetchDataException('Error inesperado al registrar psicólogo: $e');
    }
  }

  @override
  Stream<dynamic?> get authStateChanges {
    return authRemoteDataSource.authStateChanges.asyncMap((fbUser) async {
      log(
        'DEBUG: Repo authStateChanges - Firebase User: ${fbUser?.uid ?? 'null'}',
        name: 'AuthRepositoryImpl',
      );

      
      if (fbUser == null) {
        log(
          'DEBUG: Repo authStateChanges - Firebase User es null. Emitiendo null.',
          name: 'AuthRepositoryImpl',
        );
        return null;
      }

      
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null || currentUser.uid != fbUser.uid) {
        log(
          '⚠️ DEBUG: Repo authStateChanges - El usuario ${fbUser.uid} recibido del stream YA NO es el current user (${currentUser?.uid ?? 'null'}). Ignorando carga de perfil y emitiendo null.',
          name: 'AuthRepositoryImpl',
        );
        return null; 
      }
      

      try {
        final userModel = await userRemoteDataSource.getUserData(fbUser.uid);
        if (userModel != null) {
          log(
            '✅ DEBUG: Repo authStateChanges - Perfil de usuario (tipo: ${userModel.runtimeType}) cargado para UID: ${fbUser.uid}',
            name: 'AuthRepositoryImpl',
          );
          return userModel;
        } else {
          
          log(
            '🔴 DEBUG: Repo authStateChanges - Usuario Firebase ${fbUser.uid} autenticado, pero NO se encontró perfil de Patient/Psychologist. Forzando signOut.',
            name: 'AuthRepositoryImpl',
          );
          await signOut(); 
          return null;
        }
      } on AppException catch (e) {
        log(
          '🔴 Error al obtener datos de usuario para authStateChanges (AppException): $e',
          name: 'AuthRepositoryImpl',
        );
        await signOut(); 
        return null;
      } catch (e) {
        log(
          '🔴 Error inesperado al obtener datos de usuario para authStateChanges: $e',
          name: 'AuthRepositoryImpl',
        );
        await signOut(); 
        return null;
      }
    });
  }

  @override
  Future<void> signOut() async {
    log(
      '🔴 ¡ALERT! Se llamó a signOut() desde AuthRepositoryImpl.',
      name: 'AuthRepositoryImpl',
    );
    try {
      await authRemoteDataSource
          .signOut(); 
      log(
        '✅ Sesión cerrada exitosamente en Firebase.',
        name: 'AuthRepositoryImpl',
      );
    } on AppException catch (e) {
      log(
        '🔴 Error de AppException al cerrar sesión en AuthRepositoryImpl: ${e.message}',
        name: 'AuthRepositoryImpl',
      );
      rethrow;
    } catch (e) {
      log(
        '🔴 Error inesperado al cerrar sesión en AuthRepositoryImpl: $e',
        name: 'AuthRepositoryImpl',
      );
      rethrow;
    }
  }
}
