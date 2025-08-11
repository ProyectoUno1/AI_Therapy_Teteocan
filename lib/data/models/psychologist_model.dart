import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PsychologistModel extends Equatable {
  final String uid;
  final String username;
  final String email;
  final String? phoneNumber;
  final String role;
  final DateTime? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profilePictureUrl;

  // Campos profesionales
  final String? fullName;
  final String? professionalTitle;
  final String? professionalLicense;
  final int? yearsExperience;
  final String? description;
  final List<String>? education;
  final List<String>? certifications;
  final String? specialty;
  final List<String>? subSpecialties;
  final Map<String, dynamic>? schedule;

 
  final double? rating;
  final bool? isAvailable;
  final double? hourlyRate;

  const PsychologistModel({
    required this.uid,
    required this.email,
    required this.username,
    this.fullName,
    this.phoneNumber,
    this.professionalLicense,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
    required this.role,
    this.profilePictureUrl,
    this.professionalTitle,
    this.yearsExperience,
    this.description,
    this.education,
    this.certifications,
    this.specialty,
    this.subSpecialties,
    this.schedule,
    this.rating,
    this.isAvailable,
    this.hourlyRate,
  });

  factory PsychologistModel.fromJson(Map<String, dynamic> json) {
    return PsychologistModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String? ?? 'psicologo',
      dateOfBirth: json['dateOfBirth'] is String
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      fullName: json['fullName'] as String?,
      professionalTitle: json['professionalTitle'] as String?,
      professionalLicense: json['professionalLicense'] as String?,
      yearsExperience: (json['yearsExperience'] as num?)?.toInt(),
      description: json['description'] as String?,
      education: (json['education'] as List?)?.cast<String>(),
      certifications: (json['certifications'] as List?)?.cast<String>(),
      specialty: json['specialty'] as String?,
      subSpecialties: (json['subSpecialties'] as List?)?.cast<String>(),
      schedule: json['schedule'] as Map<String, dynamic>?,
      rating: (json['rating'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
    );
  }

  factory PsychologistModel.fromFirestore(Map<String, dynamic> data) {
    return PsychologistModel(
      uid: data['firebase_uid'] as String? ?? data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      phoneNumber: data['phone_number'] as String?,
      professionalLicense: data['professional_license'] as String?,
      dateOfBirth: (data['date_of_birth'] is Timestamp)
          ? (data['date_of_birth'] as Timestamp?)?.toDate()
          : null,
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp?)?.toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp?)?.toDate()
          : null,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      role: data['role'] as String? ?? 'psicologo',
      fullName: data['fullName'] as String?,
      professionalTitle: data['professionalTitle'] as String?,
      yearsExperience: (data['yearsExperience'] as num?)?.toInt(),
      description: data['description'] as String?,
      education: (data['education'] as List?)?.cast<String>(),
      certifications: (data['certifications'] as List?)?.cast<String>(),
      specialty: data['specialty'] as String?,
      subSpecialties: (data['subSpecialties'] as List?)?.cast<String>(),
      schedule: data['schedule'] as Map<String, dynamic>?,
      rating: (data['rating'] as num?)?.toDouble(),
      isAvailable: data['isAvailable'] as bool? ?? false,
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'professionalLicense': professionalLicense,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'fullName': fullName,
      'professionalTitle': professionalTitle,
      'yearsExperience': yearsExperience,
      'description': description,
      'education': education,
      'certifications': certifications,
      'specialty': specialty,
      'subSpecialties': subSpecialties,
      'schedule': schedule,
      'rating': rating,
      'isAvailable': isAvailable,
      'hourlyRate': hourlyRate,
    };
  }

  @override
  List<Object?> get props => [
    uid,
    username,
    email,
    phoneNumber,
    role,
    dateOfBirth,
    createdAt,
    updatedAt,
    profilePictureUrl,
    fullName,
    professionalTitle,
    professionalLicense,
    yearsExperience,
    description,
    specialty,
    subSpecialties,
    education,
    certifications,
    schedule,
    rating,
    isAvailable,
    hourlyRate,
  ];
}