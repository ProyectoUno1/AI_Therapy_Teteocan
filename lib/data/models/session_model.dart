// lib/data/models/session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType {
  therapy,
  initial,
  followUp,
  emergency;

  String get displayName {
    switch (this) {
      case SessionType.therapy:
        return 'Sesión de terapia';
      case SessionType.initial:
        return 'Consulta inicial';
      case SessionType.followUp:
        return 'Seguimiento';
      case SessionType.emergency:
        return 'Emergencia';
    }
  }
}

enum SessionStatus {
  scheduled,
  completed,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case SessionStatus.scheduled:
        return 'Programada';
      case SessionStatus.completed:
        return 'Completada';
      case SessionStatus.cancelled:
        return 'Cancelada';
      case SessionStatus.noShow:
        return 'No asistió';
    }
  }
}

class SessionModel {
  final String? id;
  final String psychologistId;
  final String patientId;
  final String patientName;
  final String? patientImageUrl;
  final DateTime scheduledTime;
  final int durationMinutes;
  final SessionType type;
  final SessionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionModel({
    this.id,
    required this.psychologistId,
    required this.patientId,
    required this.patientName,
    this.patientImageUrl,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.type,
    this.status = SessionStatus.scheduled,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Conversión de/a Firestore
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      psychologistId: data['psychologistId'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientImageUrl: data['patientImageUrl'],
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 60,
      type: SessionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SessionType.therapy,
      ),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'psychologistId': psychologistId,
      'patientId': patientId,
      'patientName': patientName,
      'patientImageUrl': patientImageUrl,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'durationMinutes': durationMinutes,
      'type': type.name,
      'status': status.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SessionModel copyWith({
    String? id,
    String? psychologistId,
    String? patientId,
    String? patientName,
    String? patientImageUrl,
    DateTime? scheduledTime,
    int? durationMinutes,
    SessionType? type,
    SessionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      psychologistId: psychologistId ?? this.psychologistId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImageUrl: patientImageUrl ?? this.patientImageUrl,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}