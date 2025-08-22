// lib/data/models/appointment_model.dart

import 'package:equatable/equatable.dart';

enum AppointmentStatus { pending, confirmed, cancelled, completed, rescheduled }

enum AppointmentType { online, inPerson }

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.rescheduled:
        return 'Reagendada';
    }
  }

  String get icon {
    switch (this) {
      case AppointmentStatus.pending:
        return '⏳';
      case AppointmentStatus.confirmed:
        return '✅';
      case AppointmentStatus.cancelled:
        return '❌';
      case AppointmentStatus.completed:
        return '🎯';
      case AppointmentStatus.rescheduled:
        return '🔄';
    }
  }
}

extension AppointmentTypeExtension on AppointmentType {
  String get displayName {
    switch (this) {
      case AppointmentType.online:
        return 'En línea';
      case AppointmentType.inPerson:
        return 'Presencial';
    }
  }

  String get icon {
    switch (this) {
      case AppointmentType.online:
        return '💻';
      case AppointmentType.inPerson:
        return '🏢';
    }
  }
}

class AppointmentModel extends Equatable {
  final String id;
  final String patientId;
  final String patientName;
  final String patientEmail;
  final String? patientProfileUrl;
  final String psychologistId;
  final String psychologistName;
  final String psychologistSpecialty;
  final String? psychologistProfileUrl;
  final DateTime scheduledDateTime;
  final int durationMinutes;
  final AppointmentType type;
  final AppointmentStatus status;
  final double price;
  final String? notes;
  final String? patientNotes;
  final String? psychologistNotes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? completedAt;
  final String? meetingLink;
  final String? address;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    this.patientProfileUrl,
    required this.psychologistId,
    required this.psychologistName,
    required this.psychologistSpecialty,
    this.psychologistProfileUrl,
    required this.scheduledDateTime,
    this.durationMinutes = 60,
    required this.type,
    this.status = AppointmentStatus.pending,
    required this.price,
    this.notes,
    this.patientNotes,
    this.psychologistNotes,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.completedAt,
    this.meetingLink,
    this.address,
  });

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientEmail,
    String? patientProfileUrl,
    String? psychologistId,
    String? psychologistName,
    String? psychologistSpecialty,
    String? psychologistProfileUrl,
    DateTime? scheduledDateTime,
    int? durationMinutes,
    AppointmentType? type,
    AppointmentStatus? status,
    double? price,
    String? notes,
    String? patientNotes,
    String? psychologistNotes,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? completedAt,
    String? meetingLink,
    String? address,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      patientProfileUrl: patientProfileUrl ?? this.patientProfileUrl,
      psychologistId: psychologistId ?? this.psychologistId,
      psychologistName: psychologistName ?? this.psychologistName,
      psychologistSpecialty:
          psychologistSpecialty ?? this.psychologistSpecialty,
      psychologistProfileUrl:
          psychologistProfileUrl ?? this.psychologistProfileUrl,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      status: status ?? this.status,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      patientNotes: patientNotes ?? this.patientNotes,
      psychologistNotes: psychologistNotes ?? this.psychologistNotes,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      completedAt: completedAt ?? this.completedAt,
      meetingLink: meetingLink ?? this.meetingLink,
      address: address ?? this.address,
    );
  }

  // Métodos de utilidad
  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isRescheduled => status == AppointmentStatus.rescheduled;

  bool get isToday {
    final now = DateTime.now();
    final appointmentDate = scheduledDateTime;
    return now.year == appointmentDate.year &&
        now.month == appointmentDate.month &&
        now.day == appointmentDate.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final appointmentDate = scheduledDateTime;
    return tomorrow.year == appointmentDate.year &&
        tomorrow.month == appointmentDate.month &&
        tomorrow.day == appointmentDate.day;
  }

  bool get isUpcoming {
    return scheduledDateTime.isAfter(DateTime.now());
  }

  String get formattedDate {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    final day = scheduledDateTime.day;
    final month = months[scheduledDateTime.month - 1];
    final year = scheduledDateTime.year;
    final weekday = weekdays[scheduledDateTime.weekday - 1];

    return '$weekday, $day de $month de $year';
  }

  String get formattedTime {
    final hour = scheduledDateTime.hour.toString().padLeft(2, '0');
    final minute = scheduledDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  DateTime get endDateTime {
    return scheduledDateTime.add(Duration(minutes: durationMinutes));
  }

  String get timeRange {
    final endTime = endDateTime;
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$formattedTime - $endHour:$endMinute';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'patientProfileUrl': patientProfileUrl,
      'psychologistId': psychologistId,
      'psychologistName': psychologistName,
      'psychologistSpecialty': psychologistSpecialty,
      'psychologistProfileUrl': psychologistProfileUrl,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'type': type.name,
      'status': status.name,
      'price': price,
      'notes': notes,
      'patientNotes': patientNotes,
      'psychologistNotes': psychologistNotes,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'completedAt': completedAt?.toIso8601String(),
      'meetingLink': meetingLink,
      'address': address,
    };
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      patientEmail: json['patientEmail'] as String,
      patientProfileUrl: json['patientProfileUrl'] as String?,
      psychologistId: json['psychologistId'] as String,
      psychologistName: json['psychologistName'] as String,
      psychologistSpecialty: json['psychologistSpecialty'] as String,
      psychologistProfileUrl: json['psychologistProfileUrl'] as String?,
      scheduledDateTime: DateTime.parse(json['scheduledDateTime'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      type: AppointmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AppointmentType.online,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      price: (json['price'] as num).toDouble(),
      notes: json['notes'] as String?,
      patientNotes: json['patientNotes'] as String?,
      psychologistNotes: json['psychologistNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      meetingLink: json['meetingLink'] as String?,
      address: json['address'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    patientName,
    patientEmail,
    patientProfileUrl,
    psychologistId,
    psychologistName,
    psychologistSpecialty,
    psychologistProfileUrl,
    scheduledDateTime,
    durationMinutes,
    type,
    status,
    price,
    notes,
    patientNotes,
    psychologistNotes,
    createdAt,
    confirmedAt,
    cancelledAt,
    cancellationReason,
    completedAt,
    meetingLink,
    address,
  ];
}