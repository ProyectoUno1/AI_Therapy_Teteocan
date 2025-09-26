// lib/data/models/patient_management_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PatientStatus {
  pending('⏳', 'Pendiente'),
  accepted('✅', 'Aceptado'),
  inTreatment('🔄', 'En Tratamiento'),
  completed('🎓', 'Completado'),
  cancelled('❌', 'Cancelado');

  final String icon;
  final String displayName;

  const PatientStatus(this.icon, this.displayName);
}

enum ContactMethod {
  appointment('📅', 'Por Cita'),
  email('📧', 'Email'),
  phone('📞', 'Teléfono'),
  whatsapp('💬', 'WhatsApp'),
  manual('✏️', 'Manual');

  final String icon;
  final String displayName;

  const ContactMethod(this.icon, this.displayName);
}

class PatientManagementModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PatientStatus status;
  final String? notes;
  final DateTime? lastAppointment;
  final DateTime? nextAppointment;
  final int totalSessions;
  final bool isActive;
  final ContactMethod contactMethod;

  PatientManagementModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.notes,
    this.lastAppointment,
    this.nextAppointment,
    required this.totalSessions,
    required this.isActive,
    required this.contactMethod,
  });

  factory PatientManagementModel.fromJson(Map<String, dynamic> json) {
    return PatientManagementModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      profilePictureUrl: json['profilePictureUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: PatientStatus.values.firstWhere(
        (e) => e.toString() == 'PatientStatus.${json['status']}',
        orElse: () => PatientStatus.pending,
      ),
      notes: json['notes'],
      lastAppointment: json['lastAppointment'] != null
          ? DateTime.parse(json['lastAppointment'])
          : null,
      nextAppointment: json['nextAppointment'] != null
          ? DateTime.parse(json['nextAppointment'])
          : null,
      totalSessions: json['totalSessions'] ?? 0,
      isActive: json['isActive'] ?? false,
      contactMethod: ContactMethod.values.firstWhere(
        (e) => e.toString() == 'ContactMethod.${json['contactMethod']}',
        orElse: () => ContactMethod.appointment,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'lastAppointment': lastAppointment?.toIso8601String(),
      'nextAppointment': nextAppointment?.toIso8601String(),
      'totalSessions': totalSessions,
      'isActive': isActive,
      'contactMethod': contactMethod.toString().split('.').last,
    };
  }

  PatientManagementModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    PatientStatus? status,
    String? notes,
    DateTime? lastAppointment,
    DateTime? nextAppointment,
    int? totalSessions,
    bool? isActive,
    ContactMethod? contactMethod,
  }) {
    return PatientManagementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      lastAppointment: lastAppointment ?? this.lastAppointment,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      totalSessions: totalSessions ?? this.totalSessions,
      isActive: isActive ?? this.isActive,
      contactMethod: contactMethod ?? this.contactMethod,
    );
  }
}
