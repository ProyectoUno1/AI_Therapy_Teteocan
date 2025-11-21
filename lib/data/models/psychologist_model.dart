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

  final String status; // 'PENDING', 'ACTIVE', 'REJECTED'
  final bool professionalInfoCompleted;
  final String? rejectionReason;

  final double? rating;
  final bool? isAvailable;
  final double? price;
  final bool? termsAccepted;

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
    this.status = 'PENDING', 
    this.professionalInfoCompleted = false, 
    this.rejectionReason,
    this.rating,
    this.isAvailable,
    this.price,
    this.termsAccepted,
  });


  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'ACTIVE'; 
  bool get isRejected => status == 'REJECTED';
  String get statusDisplayText {
    switch (status) {
      case 'PENDING':
        return 'Pendiente de aprobación';
      case 'ACTIVE':
        return 'Aprobado';
      case 'REJECTED':
        return 'Rechazado';
      default:
        return 'Estado desconocido';
    }
  }

  

  factory PsychologistModel.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para convertir Timestamp a DateTime
    DateTime? _toDateTime(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (timestamp is String) return DateTime.tryParse(timestamp);
      return null;
    }

    // Función auxiliar para convertir listas dinámicas a List<String>
    List<String>? _toStringList(dynamic list) {
      if (list == null) return null;
      return (list as List).map((e) => e.toString()).toList();
    }
    
    // Función para obtener booleano con valor por defecto
    bool _getBool(dynamic value) {
      if (value is bool) return value;
      return false; 
    }

    return PsychologistModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: json['role'] as String? ?? 'psychologist',

      // Campos básicos
      phoneNumber: json['phoneNumber'] as String?,
      dateOfBirth: _toDateTime(json['dateOfBirth']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      fullName: json['fullName'] as String?,

      // Campos profesionales
      professionalTitle: json['professionalTitle'] as String?,
      professionalLicense: json['professionalLicense'] as String?,
      yearsExperience: json['yearsExperience'] as int?,
      description: json['description'] as String?,
      education: _toStringList(json['education']),
      certifications: _toStringList(json['certifications']),
      specialty: json['specialty'] as String?,
      subSpecialties: _toStringList(json['subSpecialties']),
      schedule: json['schedule'] as Map<String, dynamic>?,

      // Campos de estado
      status: json['status'] as String? ?? 'PENDING',
      professionalInfoCompleted: _getBool(json['professionalInfoCompleted']),
      rejectionReason: json['rejectionReason'] as String?,

      // Campos de rating y disponibilidad
      rating: (json['rating'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool?,
      
      // 👇 SOLUCIÓN AL PROBLEMA DEL PRECIO
      price: (json['price'] as num?)?.toDouble() ?? 0.0, 
      
      termsAccepted: json['termsAccepted'] as bool?
    );
  }

  factory PsychologistModel.fromFirestore(Map<String, dynamic> data) {
  return PsychologistModel(
    uid: data['firebaseUid'] as String? ?? data['uid'] as String? ?? '',
    email: data['email'] as String? ?? '',
    username: data['username'] as String? ?? '',
    phoneNumber: data['phoneNumber'] as String?,
    professionalLicense: data['professionalLicense'] as String?,
    dateOfBirth: data['dateOfBirth'] != null
        ? (data['dateOfBirth'] is Timestamp
            ? (data['dateOfBirth'] as Timestamp).toDate()
            : data['dateOfBirth'] is String
                ? DateTime.tryParse(data['dateOfBirth'])
                : null)
        : null,
    
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null)
        : null,
    
    updatedAt: data['updatedAt'] != null
        ? (data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : null)
        : null,
    
    profilePictureUrl: data['profilePictureUrl'] as String?,
    role: data['role'] as String? ?? 'psychologist',
    fullName: data['fullName'] as String?,
    professionalTitle: data['professionalTitle'] as String?,
    yearsExperience: (data['yearsExperience'] as num?)?.toInt(),
    description: data['description'] as String?,
    
    education: data['education'] != null
        ? List<String>.from(data['education'] as List)
        : [],
    
    certifications: data['certifications'] != null
        ? List<String>.from(data['certifications'] as List)
        : [],
    
    specialty: data['specialty'] as String?,
    
    subSpecialties: data['subSpecialties'] != null
        ? List<String>.from(data['subSpecialties'] as List)
        : [],
    
    schedule: data['schedule'] as Map<String, dynamic>?,
    status: data['status'] as String? ?? 'pending',
    professionalInfoCompleted: data['professionalInfoCompleted'] as bool? ?? false,
    rejectionReason: data['rejectionReason'] as String?,
    rating: (data['rating'] as num?)?.toDouble(),
    isAvailable: data['isAvailable'] as bool? ?? true,
    price: (data['price'] as num?)?.toDouble(),
    termsAccepted: data['termsAccepted'] as bool?,
  );
}


  Map<String, dynamic> toFirestore() {
  return {
    'firebaseUid': uid,
    'email': email,
    'username': username,
    'phoneNumber': phoneNumber,
    'professionalLicense': professionalLicense,
    'profilePictureUrl': profilePictureUrl,
    'role': role,
    'dateOfBirth': dateOfBirth != null 
        ? Timestamp.fromDate(dateOfBirth!) 
        : null,
    'createdAt': createdAt != null 
        ? Timestamp.fromDate(createdAt!) 
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null 
        ? Timestamp.fromDate(updatedAt!) 
        : FieldValue.serverTimestamp(),
    'fullName': fullName,
    'professionalTitle': professionalTitle,
    'yearsExperience': yearsExperience,
    'description': description,
    'education': education,
    'certifications': certifications,
    'specialty': specialty,
    'subSpecialties': subSpecialties,
    'schedule': schedule,
    'status': status,
    'professionalInfoCompleted': professionalInfoCompleted,
    'rejectionReason': rejectionReason,
    'rating': rating,
    'isAvailable': isAvailable,
    'price': price,
    'termsAccepted': termsAccepted,
  };
}

  PsychologistModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? phoneNumber,
    String? role,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePictureUrl,
    String? fullName,
    String? professionalTitle,
    String? professionalLicense,
    int? yearsExperience,
    String? description,
    List<String>? education,
    List<String>? certifications,
    String? specialty,
    List<String>? subSpecialties,
    Map<String, dynamic>? schedule,
    String? status,
    bool? professionalInfoCompleted,
    String? rejectionReason,
    double? rating,
    bool? isAvailable,
    double? price,
    bool? termsAccepted,
  }) {
    return PsychologistModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl, 
      fullName: fullName ?? this.fullName,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      professionalLicense: professionalLicense ?? this.professionalLicense,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      description: description ?? this.description,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      specialty: specialty ?? this.specialty,
      subSpecialties: subSpecialties ?? this.subSpecialties,
      schedule: schedule ?? this.schedule,
      status: status ?? this.status,
      professionalInfoCompleted: professionalInfoCompleted ?? this.professionalInfoCompleted,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rating: rating ?? this.rating,
      isAvailable: isAvailable ?? this.isAvailable,
      price: price ?? this.price,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
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
    status,
    professionalInfoCompleted,
    rejectionReason,
    rating,
    isAvailable,
    price,
    termsAccepted,
  ];
}