// lib/data/datasources/user_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';


abstract class UserRemoteDataSource {
  Future<PatientModel> getPatientData(String uid);
  Future<PsychologistModel> getPsychologistData(String uid);
  

  Future<PatientModel> createPatient({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required DateTime dateOfBirth,
    String? profilePictureUrl,
    required String role,
  });

  Future<PsychologistModel> createPsychologist({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required String professionalLicense,
    required DateTime dateOfBirth,
    String? profilePictureUrl,
    required String role,
  });
  
  Future<void> updatePatientData({
    required String uid,
    String? username,
    String? dateOfBirth,
    String? phoneNumber,
    String? profilePictureUrl,
  });

  Future<dynamic> getUserData(String uid);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSourceImpl(this._firestore);
  
  @override
  Future<void> updatePatientData({
    required String uid,
    String? username,
    String? dateOfBirth,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    try {
      final docRef = _firestore.collection('patients').doc(uid);
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (username != null) updateData['username'] = username;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (profilePictureUrl != null) updateData['profilePictureUrl'] = profilePictureUrl;

      await docRef.update(updateData);
    } on FirebaseException catch (e) {
      throw FetchDataException('Error de Firestore al actualizar datos: ${e.message}');
    } catch (e) {
      throw FetchDataException('Error inesperado al actualizar datos de paciente: $e');
    }
  }

  @override
  Future<PatientModel> getPatientData(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('patients')
          .doc(uid)
          .withConverter<PatientModel>(
            fromFirestore: PatientModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          )
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data()!;
      } else {
        throw NotFoundException('Paciente no encontrado con UID: $uid');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw FetchDataException('Error al obtener datos del paciente de Firestore: $e');
    }
  }

  @override
  Future<PsychologistModel> getPsychologistData(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('psychologists')
          .doc(uid)
          .withConverter<PsychologistModel>(
            fromFirestore: PsychologistModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          )
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data()!;
      } else {
        throw NotFoundException('Psicólogo no encontrado con UID: $uid');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw FetchDataException('Error al obtener datos del psicólogo de Firestore: $e');
    }
  }

  @override
  Future<PatientModel> createPatient({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required DateTime dateOfBirth,
    String? profilePictureUrl,
    required String role,
  }) async {
    try {
      final now = DateTime.now();
      final patientModel = PatientModel(
        uid: uid,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        profilePictureUrl: profilePictureUrl,
        createdAt: now,
        updatedAt: now,
        role:role,
      );

      await _firestore
          .collection('patients')
          .doc(uid)
          .set(patientModel.toFirestore());

      return patientModel;
    } catch (e) {
      if (e is AppException) rethrow;
      throw CreateDataException('Error al crear paciente en Firestore: $e');
    }
  }

  @override
  Future<PsychologistModel> createPsychologist({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    required String professionalLicense,
    required DateTime dateOfBirth,
    String? profilePictureUrl,
    required String role,
  }) async {
    try {
      final now = DateTime.now();
      final psychologistModel = PsychologistModel(
        uid: uid,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        professionalLicense: professionalLicense,
        dateOfBirth: dateOfBirth,
        profilePictureUrl: profilePictureUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('psychologists')
          .doc(uid)
          .set(psychologistModel.toFirestore());

      return psychologistModel;
    } catch (e) {
      if (e is AppException) rethrow;
      throw CreateDataException('Error al crear psicólogo en Firestore: $e');
    }
  }

  @override
  Future<dynamic> getUserData(String uid) async {
    try {
      try {
        final psychologistData = await getPsychologistData(uid);
        return psychologistData;
      } on NotFoundException {
        final patientData = await getPatientData(uid);
        return patientData;
      }
    } on NotFoundException {
      throw NotFoundException('Usuario no encontrado en ninguna colección de Firestore para UID: $uid');
    } catch (e) {
      if (e is AppException) rethrow;
      throw FetchDataException('Error al obtener datos de usuario de Firestore: $e');
    }
  }
}