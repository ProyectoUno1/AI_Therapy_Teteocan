// user_repository_impl.dart
import 'package:ai_therapy_teteocan/domain/entities/patient_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore firestore;

  UserRepositoryImpl({FirebaseFirestore? firestoreInstance})
      : firestore = firestoreInstance ?? FirebaseFirestore.instance;

  @override
  Future<UserEntity> getUserRoleAndData(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Usuario no encontrado en users');
    }

    final data = doc.data()!;
    return UserEntity(
      uid: data['uid'],
      email: data['email'],
      role: data['role'],
      username: data['username'],
      phoneNumber: data['phoneNumber'],
      professionalId: data['professionalId'],
      profilePictureUrl: data['profilePictureUrl'],
    );
  }

  @override
  Future<void> updatePatientProfile(PatientEntity patient) async {}

  @override
  Future<void> updatePsychologistProfile(PsychologistEntity psychologist) async {}
}
