// lib/data/repositories/auth_repository_impl.dart

import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
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

  // --- IMPLEMENTACIÓN DEL MÉTODO FALTANTE PARA RESOLVER EL ERROR ---
  // Este método ahora es la lógica central para obtener el perfil del usuario.
  @override
  Future<dynamic> getUserProfile(String uid) async {
    // Intentamos obtener el perfil del paciente
    final patientProfile = await getPatientData(uid);
    if (patientProfile != null) {
      log('getUserProfile: Perfil de Paciente encontrado para UID: $uid', name: 'AuthRepositoryImpl');
      return patientProfile;
    }

    // Si no es paciente, intentamos obtener el perfil del psicólogo
    final psychologistProfile = await getPsychologistData(uid);
    if (psychologistProfile != null) {
      log('getUserProfile: Perfil de Psicólogo encontrado para UID: $uid', name: 'AuthRepositoryImpl');
      return psychologistProfile;
    }

    // Si no se encuentra ninguno, devolvemos null
    log('getUserProfile: No se encontró perfil para UID: $uid', name: 'AuthRepositoryImpl');
    return null;
  }

  @override
  Stream<dynamic> get authStateChanges {
    // Ahora solo reenvía el stream de Firebase sin lógica adicional,
    // ya que la lógica para cargar el perfil está ahora en getUserProfile()
    // y es manejada por el AuthBloc. Esto simplifica el repositorio.
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<PatientModel?> getPatientData(String uid) {
    return userRemoteDataSource.getPatientData(uid);
  }

  @override
  Future<PsychologistModel?> getPsychologistData(String uid) {
    return userRemoteDataSource.getPsychologistData(uid);
  }

  @override
  Future<void> updatePatientInfo({
    required String userId,
    String? name,
    String? dob,
    String? phone,
  }) async {
    log(' Repo: Iniciando actualización de datos para el paciente $userId',
        name: 'AuthRepositoryImpl');
    try {
      await userRemoteDataSource.updatePatientData(
        uid: userId,
        username: name,
        dateOfBirth: dob,
        phoneNumber: phone,
      );
      log(' Repo: Datos del paciente $userId actualizados exitosamente en Firestore.',
          name: 'AuthRepositoryImpl');
    } on AppException {
      rethrow;
    } catch (e) {
      log(' Repo: Error genérico al actualizar datos del paciente: $e',
          name: 'AuthRepositoryImpl');
      throw AuthException('Error inesperado al actualizar perfil: $e');
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    log(' Repo: Iniciando sesión para $email', name: 'AuthRepositoryImpl');
    try {
      await authRemoteDataSource.signIn(email: email, password: password);
      log(
        ' Repo: Inicio de sesión en Firebase exitoso.',
        name: 'AuthRepositoryImpl',
      );
    } on FirebaseAuthException catch (e) {
      log(
        ' Repo: FirebaseAuthException: ${e.code} - ${e.message}',
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
      throw AuthException(
          'Error de autenticación: ${e.message ?? e.code}');
    } on AppException {
      rethrow;
    } catch (e) {
      log(
        ' Repo: Error genérico al iniciar sesión: $e',
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
      ' Repo: Iniciando registro de paciente para $email',
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
        ' Repo: Registro de paciente y datos de Firestore exitoso.',
        name: 'AuthRepositoryImpl',
      );

      return patient;
    } on FirebaseAuthException catch (e) {
      log(
        ' Repo: FirebaseAuthException en registro de paciente: ${e.code} - ${e.message}',
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
        ' ERROR CAPTURADO en AuthRepositoryImpl.registerPatient: $e',
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
    String? profilePictureUrl,
  }) async {
    log(
      ' Repo: Iniciando registro de psicólogo para $email',
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
        profilePictureUrl: profilePictureUrl,
        createdAt: now,
        updatedAt: now,
        role: 'psychologist',
      );

      await userRemoteDataSource.createPsychologist(
        uid: psychologist.uid,
        username: psychologist.username,
        email: psychologist.email,
        phoneNumber: psychologist.phoneNumber ?? '',
        professionalLicense: psychologist.professionalLicense ?? '',
        dateOfBirth: psychologist.dateOfBirth!,
        profilePictureUrl: psychologist.profilePictureUrl,
        role: psychologist.role,
      );
      log(
        ' Repo: Registro de psicólogo y datos de Firestore exitoso.',
        name: 'AuthRepositoryImpl',
      );

      return psychologist;
    } on FirebaseAuthException catch (e) {
      log(
        ' Repo: FirebaseAuthException en registro de psicólogo: ${e.code} - ${e.message}',
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
        ' ERROR CAPTURADO en AuthRepositoryImpl.registerPsychologist: $e',
        name: 'AuthRepositoryImpl',
      );
      throw FetchDataException('Error inesperado al registrar psicólogo: $e');
    }
  }

  @override
  Future<void> signOut() async {
    log(
      ' ¡ALERT! Se llamó a signOut() desde AuthRepositoryImpl.',
      name: 'AuthRepositoryImpl',
    );
    try {
      await authRemoteDataSource.signOut();
      log(
        ' Sesión cerrada exitosamente en Firebase.',
        name: 'AuthRepositoryImpl',
      );
    } on AppException catch (e) {
      log(
        ' Error de AppException al cerrar sesión en AuthRepositoryImpl: ${e.message ?? 'Unknown error'}',
        name: 'AuthRepositoryImpl',
      );
      rethrow;
    } catch (e) {
      log(
        ' Error inesperado al cerrar sesión en AuthRepositoryImpl: $e',
        name: 'AuthRepositoryImpl',
      );
      rethrow;
    }
  }
}