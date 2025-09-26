// lib/domain/repositories/auth_repository.dart

import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<dynamic> get authStateChanges;
  Future<PatientModel> registerPatient({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required DateTime dateOfBirth,
  });
  Future<PsychologistModel> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalLicense,
    required DateTime dateOfBirth,
  });
  Future<PatientModel?> getPatientData(String uid);
  Future<PsychologistModel?> getPsychologistData(String uid);
  Future<void> updatePatientInfo({
    required String userId,
    String? name,
    String? dob,
    String? phone,
  });
}
