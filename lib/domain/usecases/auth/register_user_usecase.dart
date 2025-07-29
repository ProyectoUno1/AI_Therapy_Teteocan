// lib/domain/usecases/register_user_usecase.dart


import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart'; 

class RegisterUserUseCase {
  final AuthRepository repository;

  RegisterUserUseCase(this.repository);


  Future<PatientModel> registerPatient({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required DateTime dateOfBirth,
    
  }) {
    return repository.registerPatient(
      email: email,
      password: password,
      username: username, 
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      
    );
  }

  
  Future<PsychologistModel> registerPsychologist({
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
    required String professionalLicense,
    required DateTime dateOfBirth,
  }) {
    return repository.registerPsychologist(
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
      professionalLicense: professionalLicense,
      dateOfBirth: dateOfBirth,
    );
  }
}