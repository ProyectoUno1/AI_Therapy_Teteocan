// lib/presentation/shared/bloc/appointment_event.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppointmentsEvent extends AppointmentEvent {
  final String userId;
  final bool isForPsychologist;

  const LoadAppointmentsEvent({
    required this.userId,
    this.isForPsychologist = false,
  });

  @override
  List<Object> get props => [userId, isForPsychologist];
}

class BookAppointmentEvent extends AppointmentEvent {
  final String psychologistId;
  final DateTime scheduledDateTime;
  final AppointmentType type;
  final String? notes;

  const BookAppointmentEvent({
    required this.psychologistId,
    required this.scheduledDateTime,
    required this.type,
    this.notes,
  });

  @override
  List<Object?> get props => [psychologistId, scheduledDateTime, type, notes];
}

class ConfirmAppointmentEvent extends AppointmentEvent {
  final String appointmentId;
  final String? psychologistNotes;
  final String? meetingLink;

  const ConfirmAppointmentEvent({
    required this.appointmentId,
    this.psychologistNotes,
    this.meetingLink,
  });

  @override
  List<Object?> get props => [appointmentId, psychologistNotes, meetingLink];
}

class CancelAppointmentEvent extends AppointmentEvent {
  final String appointmentId;
  final String reason;
  final bool isPsychologistCancelling;

  const CancelAppointmentEvent({
    required this.appointmentId,
    required this.reason,
    this.isPsychologistCancelling = false,
  });

  @override
  List<Object> get props => [appointmentId, reason, isPsychologistCancelling];
}

class RescheduleAppointmentEvent extends AppointmentEvent {
  final String appointmentId;
  final DateTime newDateTime;
  final String? reason;

  const RescheduleAppointmentEvent({
    required this.appointmentId,
    required this.newDateTime,
    this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, newDateTime, reason];
}

class CompleteAppointmentEvent extends AppointmentEvent {
  final String appointmentId;
  final String? notes;

  const CompleteAppointmentEvent({required this.appointmentId, this.notes});

  @override
  List<Object?> get props => [appointmentId, notes];
}

class LoadAvailableTimeSlotsEvent extends AppointmentEvent {
  final String psychologistId;
  final DateTime date;

  const LoadAvailableTimeSlotsEvent({
    required this.psychologistId,
    required this.date,
  });

  @override
  List<Object> get props => [psychologistId, date];
}

class GetAppointmentDetailsEvent extends AppointmentEvent {
  final String appointmentId;

  const GetAppointmentDetailsEvent(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

// EVENTO TEMPORAL PARA CARGAR CITAS DE MUESTRA (SOLO PARA PRUEBAS)
class LoadSampleAppointmentsEvent extends AppointmentEvent {
  final List<AppointmentModel> appointments;

  const LoadSampleAppointmentsEvent({required this.appointments});

  @override
  List<Object> get props => [appointments];
}
