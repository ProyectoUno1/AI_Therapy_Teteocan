// lib/domain/repositories/user_repository.dart
import 'package:ai_therapy_teteocan/domain/entities/patient_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity> getUserRoleAndData(String uid);
  Future<void> updatePatientProfile(PatientEntity patient);
  Future<void> updatePsychologistProfile(PsychologistEntity psychologist);
}
