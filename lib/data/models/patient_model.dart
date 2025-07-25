import 'package:ai_therapy_teteocan/data/models/user_model.dart';
import 'package:ai_therapy_teteocan/domain/entities/patient_entity.dart';

class PatientModel extends UserModel {
  final String? dateOfBirth;
  final String? gender;

  const PatientModel({
    required String uid,
    required String username,
    required String email,
    required String phoneNumber,
    String? profilePictureUrl,
    this.dateOfBirth,
    this.gender,
  }) : super(
         uid: uid,
         username: username,
         email: email,
         phoneNumber: phoneNumber,
         role: 'paciente',
         profilePictureUrl: profilePictureUrl,
       );

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      uid: json['firebaseUid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,  // Nota: usa snake_case si así lo guardas en DB
      gender: json['gender'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['date_of_birth'] = dateOfBirth;
    json['gender'] = gender;
    return json;
  }

  factory PatientModel.fromEntity(PatientEntity entity) {
    return PatientModel(
      uid: entity.uid,
      username: entity.username,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      profilePictureUrl: entity.profilePictureUrl,
      dateOfBirth: (entity as dynamic).dateOfBirth,
      gender: (entity as dynamic).gender,
    );
  }
}
