// lib/presentation/patient/bloc/psychology_payment_state.dart

abstract class PsychologyPaymentState {}

class PsychologyPaymentInitial extends PsychologyPaymentState {}

class PsychologyPaymentLoading extends PsychologyPaymentState {}

class PsychologyPaymentCheckoutSuccess extends PsychologyPaymentState {
  final String checkoutUrl;
  final String sessionId;
  final String? psychologySessionId;

  PsychologyPaymentCheckoutSuccess({
    required this.checkoutUrl,
    required this.sessionId,
    this.psychologySessionId,
  });
}

class PsychologyPaymentSuccess extends PsychologyPaymentState {
  final String message;
  final String sessionId;
  final String? psychologySessionId;

  PsychologyPaymentSuccess({
    required this.message,
    required this.sessionId,
    this.psychologySessionId,
  });
}

class PsychologyPaymentError extends PsychologyPaymentState {
  final String message;

  PsychologyPaymentError({required this.message});
}