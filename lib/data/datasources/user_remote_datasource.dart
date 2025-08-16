import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/patient_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/core/exceptions/app_exceptions.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

abstract class UserRemoteDataSource {
  Future<PatientModel?> getPatientData(String uid);
  Future<PsychologistModel?> getPsychologistData(String uid);

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

  Future<void> updateBasicPsychologistData({
    required String uid,
    String? username,
    String? phoneNumber,
    String? profilePictureUrl,
  });

  Future<void> updateProfessionalPsychologistData({
    required String uid,
    String? professionalLicense,
    String? professionalTitle,
    int? yearsExperience,
    String? description,
    List<String>? education,
    List<String>? certifications,
    String? specialty,
    List<String>? subSpecialties,
    Map<String, dynamic>? schedule,
  });

  Future<dynamic> getUserData(String uid);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  // URL base 
  static const String _baseUrl = 'http://10.0.2.2:3000';


  UserRemoteDataSourceImpl(this._firestore);
Future<String> _getFirebaseIdToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw FetchDataException('No hay usuario autenticado');
  }
  final token = await user.getIdToken();
  if (token == null) {
    throw FetchDataException('No se pudo obtener el token de autenticación');
  }
  return token;
}


  @override
  Future<PatientModel?> getPatientData(String uid) async {
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
      }
      return null;
    } on FirebaseException catch (e) {
      log('Error de Firestore al obtener datos del paciente: ${e.message}',
          name: 'UserRemoteDataSourceImpl');
      throw FetchDataException('Error de Firestore: ${e.message}');
    } catch (e) {
      log('Error inesperado al obtener datos del paciente: $e',
          name: 'UserRemoteDataSourceImpl');
      if (e is AppException) rethrow;
      throw FetchDataException('Error al obtener datos del paciente: $e');
    }
  }

  @override
  Future<PsychologistModel?> getPsychologistData(String uid) async {
    try {
      final psychologistDoc =
          await _firestore.collection('psychologists').doc(uid).get();
      if (!psychologistDoc.exists) {
        return null;
      }
      final coreData = psychologistDoc.data() as Map<String, dynamic>;

      final professionalInfoDoc = await _firestore
          .collection('psychologist_professional_info')
          .doc(uid)
          .get();

      if (professionalInfoDoc.exists && professionalInfoDoc.data() != null) {
        coreData.addAll(professionalInfoDoc.data() as Map<String, dynamic>);
      }

      return PsychologistModel.fromFirestore(coreData);
    } on FirebaseException catch (e) {
      log('Error de Firestore al obtener datos del psicólogo: ${e.message}',
          name: 'UserRemoteDataSourceImpl');
      throw FetchDataException('Error de Firestore: ${e.message}');
    } catch (e) {
      log('Error inesperado al obtener datos del psicólogo: $e',
          name: 'UserRemoteDataSourceImpl');
      if (e is AppException) rethrow;
      throw FetchDataException('Error al obtener datos del psicólogo: $e');
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
        role: role,
      );

      await _firestore
          .collection('patients')
          .doc(uid)
          .set(patientModel.toFirestore());

      return patientModel;
    } on FirebaseException catch (e) {
      log('Error de Firestore al crear paciente: ${e.message}',
          name: 'UserRemoteDataSourceImpl');
      throw CreateDataException('Error de Firestore: ${e.message}');
    } catch (e) {
      log('Error inesperado al crear paciente: $e',
          name: 'UserRemoteDataSourceImpl');
      if (e is AppException) rethrow;
      throw CreateDataException('Error al crear paciente: $e');
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
        role: role,
      );

      final psychologistCoreData = {
        'uid': uid,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth,
        'profilePictureUrl': profilePictureUrl,
        'createdAt': now,
        'updatedAt': now,
        'role': role,
      };
      await _firestore
          .collection('psychologists')
          .doc(uid)
          .set(psychologistCoreData);

      final psychologistProfessionalData = {
        'uid': uid,
        'professionalLicense': professionalLicense,
        'createdAt': now,
        'updatedAt': now,
      };
      await _firestore
          .collection('psychologist_professional_info')
          .doc(uid)
          .set(psychologistProfessionalData);

      return psychologistModel;
    } on FirebaseException catch (e) {
      log('Error de Firestore al crear psicólogo: ${e.message}',
          name: 'UserRemoteDataSourceImpl');
      throw CreateDataException('Error de Firestore: ${e.message}');
    } catch (e) {
      log('Error inesperado al crear psicólogo: $e',
          name: 'UserRemoteDataSourceImpl');
      if (e is AppException) rethrow;
      throw CreateDataException('Error al crear psicólogo: $e');
    }
  }

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
      if (profilePictureUrl != null) {
        updateData['profilePictureUrl'] = profilePictureUrl;
      }

      await docRef.set(updateData, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      log('Error de Firestore al actualizar datos del paciente: ${e.message}',
          name: 'UserRemoteDataSourceImpl');
      throw FetchDataException('Error de Firestore: ${e.message}');
    } catch (e) {
      log('Error inesperado al actualizar datos del paciente: $e',
          name: 'UserRemoteDataSourceImpl');
      if (e is AppException) rethrow;
      throw FetchDataException('Error al actualizar datos de paciente: $e');
    }
  }

  @override
Future<void> updateBasicPsychologistData({
  required String uid,
  String? username,
  String? phoneNumber,
  String? profilePictureUrl,
}) async {
  final Map<String, dynamic> data = {};
  if (username != null) data['username'] = username;
  if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
  if (profilePictureUrl != null) data['profilePictureUrl'] = profilePictureUrl;
  
  if (data.isNotEmpty) {
    await _firestore.collection('psychologists').doc(uid).update(data);
  }
}

  @override
  Future<void> updateProfessionalPsychologistData({
    required String uid,
    String? professionalLicense,
    String? professionalTitle,
    int? yearsExperience,
    String? description,
    List<String>? education,
    List<String>? certifications,
    String? specialty,
    List<String>? subSpecialties,
    Map<String, dynamic>? schedule,
  }) async {
    try {
      final token = await _getFirebaseIdToken();
      final updateData = <String, dynamic>{};

      if (professionalLicense != null) {
        updateData['professionalLicense'] = professionalLicense;
      }
      if (professionalTitle != null) {
        updateData['professionalTitle'] = professionalTitle;
      }
      if (yearsExperience != null) {
        updateData['yearsExperience'] = yearsExperience;
      }
      if (description != null) updateData['description'] = description;
      if (education != null) updateData['education'] = education;
      if (certifications != null) updateData['certifications'] = certifications;
      if (specialty != null) updateData['specialty'] = specialty;
      if (subSpecialties != null) updateData['subSpecialties'] = subSpecialties;
      if (schedule != null) updateData['schedule'] = schedule;

      final response = await http.patch(
      Uri.parse('$_baseUrl/api/psychologists/$uid/professional'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    );

      if (response.statusCode != 200) {
        throw FetchDataException(
            'Error al actualizar datos profesionales: ${response.body}');
      }
    } catch (e) {
      log('Error al actualizar datos profesionales vía backend: $e',
          name: 'UserRemoteDataSourceImpl');
      if (e is AppException) rethrow;
      throw FetchDataException('Error al actualizar datos profesionales: $e');
    }
  }

  @override
  Future<dynamic> getUserData(String uid) async {
    try {
      final psychologistData = await getPsychologistData(uid);
      if (psychologistData != null) {
        return psychologistData;
      }

      final patientData = await getPatientData(uid);
      if (patientData != null) {
        return patientData;
      }

      throw NotFoundException(
          'Usuario no encontrado en ninguna colección de Firestore para UID: $uid');
    } on NotFoundException {
      rethrow;
    } on FirebaseException catch (e) {
      log('Error de Firestore al obtener datos de usuario: ${e.message}',
          name: 'UserRemoteDataSourceImpl');
      throw FetchDataException('Error de Firestore: ${e.message}');
    } catch (e) {
      log('Error inesperado al obtener datos de usuario: $e',
          name: 'UserRemoteDataSourceImpl');
      if (e is AppException) rethrow;
      throw FetchDataException('Error al obtener datos de usuario: $e');
    }
  }
}
