// lib/domain/repositories/auth_repository.dart

import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Para el tipo de User de Firebase

abstract class AuthRepository {
  // Retorna dynamic porque puede ser PsychologistModel o PatientModel
  Future<dynamic> signIn({
    required String email,
    required String password,
  });

  Future<PatientModel> registerPatient({
    required String email,
    required String password,
    required String username, // Cambiado de username
    required String phoneNumber,
    required DateTime dateOfBirth, // Cambiado a DateTime
  });

  Future<PsychologistModel> registerPsychologist({
    required String email,
    required String password,
    required String username, // Cambiado de username
    required String phoneNumber,
    required String professionalLicense,
    required DateTime dateOfBirth, // Cambiado a DateTime
  });

  Future<void> signOut();

  // Retorna dynamic para el modelo, o null si no hay usuario logueado
  Stream<dynamic?> get authStateChanges;
  

}