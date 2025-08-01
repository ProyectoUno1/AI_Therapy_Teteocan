// lib/domain/repositories/auth_repository.dart


import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';

abstract class AuthRepository {
  // Un stream para escuchar los cambios en el estado de autenticación.
  Stream<dynamic?> get authStateChanges;

  // Método para iniciar sesión con email y contraseña.
  Future<void> signIn({required String email, required String password});

  // Método para registrar a un nuevo paciente.
  Future<PatientModel> registerPatient({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required DateTime dateOfBirth,
  });

  // Método para registrar a un nuevo psicólogo.
  Future<PsychologistModel> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalLicense,
    required DateTime dateOfBirth,
  });
  
  // Nuevo método para actualizar la información del paciente.
  Future<void> updatePatientInfo({
    required String userId,
    String? name,
    String? dob,
    String? phone,
  });

  // Permite obtener los datos de un paciente por su UID.
  Future<PatientModel> getPatientData(String uid);

  // Método para cerrar sesión.
  Future<void> signOut();
}