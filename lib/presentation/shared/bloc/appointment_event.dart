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
  final DateTime startDate; 
  final DateTime endDate;

  const LoadAppointmentsEvent({
    required this.userId,
    this.isForPsychologist = false,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [userId, isForPsychologist, startDate, endDate];
}

class BookAppointmentEvent extends AppointmentEvent {
  final String psychologistId;
  final String patientId;
  final DateTime scheduledDateTime;
  final AppointmentType type;
  final String? notes;
  
  const BookAppointmentEvent({
    required this.psychologistId,
    required this.patientId,
    required this.scheduledDateTime,
    required this.type,
    this.notes,
  });

  @override
  List<Object?> get props => [psychologistId, patientId, scheduledDateTime, type, notes];
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
  final DateTime startDate;
  final DateTime endDate;

  const LoadAvailableTimeSlotsEvent({
    required this.psychologistId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [psychologistId, startDate, endDate];
}

class GetAppointmentDetailsEvent extends AppointmentEvent {
  final String appointmentId;

  const GetAppointmentDetailsEvent(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

class LoadSampleAppointmentsEvent extends AppointmentEvent {
  final List<AppointmentModel> appointments;

  const LoadSampleAppointmentsEvent({required this.appointments});

  @override
  List<Object> get props => [appointments];
}

class RateAppointmentEvent extends AppointmentEvent {
  final String appointmentId;
  final int rating;
  final String? comment;

  const RateAppointmentEvent({
    required this.appointmentId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [appointmentId, rating, comment];
}

class StartAppointmentSessionEvent extends AppointmentEvent {
  final String appointmentId;

  const StartAppointmentSessionEvent({required this.appointmentId});

  @override
  List<Object> get props => [appointmentId];
}

class CompleteAppointmentSessionEvent extends AppointmentEvent {
  final String appointmentId;
  final String? notes;

  const CompleteAppointmentSessionEvent({
    required this.appointmentId,
    this.notes,
  });

  @override
  List<Object?> get props => [appointmentId, notes];
}
