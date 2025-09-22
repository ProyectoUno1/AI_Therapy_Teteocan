// lib/presentation/patient/bloc/psychology_payment_event.dart

abstract class PsychologyPaymentEvent {}

class StartPsychologyPaymentEvent extends PsychologyPaymentEvent {
  final String userEmail;
  final String userId;
  final String? userName;
  final String sessionDate;
  final String sessionTime;
  final String psychologistName;
  final String psychologistId;
  final String? sessionNotes;

  StartPsychologyPaymentEvent({
    required this.userEmail,
    required this.userId,
    this.userName,
    required this.sessionDate,
    required this.sessionTime,
    required this.psychologistName,
    required this.psychologistId,
    this.sessionNotes,
  });
}

class VerifyPsychologyPaymentEvent extends PsychologyPaymentEvent {
  final String sessionId;

  VerifyPsychologyPaymentEvent({required this.sessionId});
}