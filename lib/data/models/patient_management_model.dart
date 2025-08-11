// lib/data/models/patient_management_model.dart

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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      profilePictureUrl: json['profile_picture_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      status: PatientStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PatientStatus.pending,
      ),
      notes: json['notes'],
      lastAppointment: json['last_appointment'] != null
          ? DateTime.parse(json['last_appointment'])
          : null,
      nextAppointment: json['next_appointment'] != null
          ? DateTime.parse(json['next_appointment'])
          : null,
      totalSessions: json['total_sessions'] ?? 0,
      isActive: json['is_active'] ?? true,
      contactMethod: ContactMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['contact_method'],
        orElse: () => ContactMethod.manual,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'last_appointment': lastAppointment?.toIso8601String(),
      'next_appointment': nextAppointment?.toIso8601String(),
      'total_sessions': totalSessions,
      'is_active': isActive,
      'contact_method': contactMethod.toString().split('.').last,
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

enum PatientStatus {
  pending, // Solicitud pendiente
  accepted, // Paciente aceptado
  inTreatment, // En tratamiento activo
  completed, // Tratamiento completado
  cancelled, // Cancelado
}

enum ContactMethod {
  manual, // Agregado manualmente por el psicólogo
  appointment, // Solicitud de cita del paciente
  chat, // Iniciado por chat
}

// Extensiones para facilitar el uso
extension PatientStatusExtension on PatientStatus {
  String get displayName {
    switch (this) {
      case PatientStatus.pending:
        return 'Pendiente';
      case PatientStatus.accepted:
        return 'Aceptado';
      case PatientStatus.inTreatment:
        return 'En Tratamiento';
      case PatientStatus.completed:
        return 'Completado';
      case PatientStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get icon {
    switch (this) {
      case PatientStatus.pending:
        return '⏳';
      case PatientStatus.accepted:
        return '✅';
      case PatientStatus.inTreatment:
        return '🔄';
      case PatientStatus.completed:
        return '🎉';
      case PatientStatus.cancelled:
        return '❌';
    }
  }
}

extension ContactMethodExtension on ContactMethod {
  String get displayName {
    switch (this) {
      case ContactMethod.manual:
        return 'Agregado Manualmente';
      case ContactMethod.appointment:
        return 'Solicitud de Cita';
      case ContactMethod.chat:
        return 'Iniciado por Chat';
    }
  }

  String get icon {
    switch (this) {
      case ContactMethod.manual:
        return '👨‍⚕️';
      case ContactMethod.appointment:
        return '📅';
      case ContactMethod.chat:
        return '💬';
    }
  }
}
