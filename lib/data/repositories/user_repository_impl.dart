// lib/data/repositories/user_repository_impl.dart
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/data/models/user_model.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/patient_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> getUserRoleAndData(String uid) async {
    try {
      final userModel = await remoteDataSource.getUserData(uid);
      return userModel;
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException(
        'Error al obtener el rol y datos del usuario: $e',
      );
    }
  }

  @override
  Future<void> updatePatientProfile(PatientEntity patient) async {
    try {
      final patientModel = PatientModel.fromEntity(patient);
      await remoteDataSource.updatePatientProfile(patientModel);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Error al actualizar perfil de paciente: $e');
    }
  }

  @override
  Future<void> updatePsychologistProfile(
    PsychologistEntity psychologist,
  ) async {
    try {
      final psychologistModel = PsychologistModel.fromEntity(psychologist);
      await remoteDataSource.updatePsychologistProfile(psychologistModel);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FetchDataException('Error al actualizar perfil de psicólogo: $e');
    }
  }
}
