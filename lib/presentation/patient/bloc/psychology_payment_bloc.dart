// lib/presentation/patient/bloc/psychology_payment_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_therapy_teteocan/data/repositories/psychology_payment_repository.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/psychology_payment_event.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/psychology_payment_state.dart';

class PsychologyPaymentBloc extends Bloc<PsychologyPaymentEvent, PsychologyPaymentState> {
  final PsychologyPaymentRepository repository;

  PsychologyPaymentBloc({required this.repository}) : super(PsychologyPaymentInitial()) {
    on<StartPsychologyPaymentEvent>(_onStartPsychologyPayment);
    on<VerifyPsychologyPaymentEvent>(_onVerifyPsychologyPayment);
  }

  Future<void> _onStartPsychologyPayment(
    StartPsychologyPaymentEvent event,
    Emitter<PsychologyPaymentState> emit,
  ) async {
    try {
      emit(PsychologyPaymentLoading());

      final result = await repository.createPsychologySession(
        userEmail: event.userEmail,
        userId: event.userId,
        userName: event.userName,
        sessionDate: event.sessionDate,
        sessionTime: event.sessionTime,
        psychologistName: event.psychologistName,
        psychologistId: event.psychologistId,
        sessionNotes: event.sessionNotes,
        appointmentType: event.appointmentType, 
      );

      if (result['checkoutUrl'] != null) {
        final uri = Uri.parse(result['checkoutUrl']);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          
          emit(PsychologyPaymentCheckoutSuccess(
            checkoutUrl: result['checkoutUrl'],
            sessionId: result['sessionId'],
            psychologySessionId: result['psychologySessionId'],
          ));
        } else {
          emit(PsychologyPaymentError(
            message: 'No se pudo abrir el navegador para el pago',
          ));
        }
      } else {
        emit(PsychologyPaymentError(
          message: 'Error al crear la sesión de pago',
        ));
      }
    } catch (e) {
      emit(PsychologyPaymentError(
        message: 'Error procesando el pago: ${e.toString()}',
      ));
    }
  }

  Future<void> _onVerifyPsychologyPayment(
    VerifyPsychologyPaymentEvent event,
    Emitter<PsychologyPaymentState> emit,
  ) async {
    try {
      emit(PsychologyPaymentLoading());

      final result = await repository.verifyPsychologySession(
        sessionId: event.sessionId,
      );

      if (result['paymentStatus'] == 'paid' && result['sessionStatus'] == 'complete') {
        emit(PsychologyPaymentSuccess(
          message: '¡Pago confirmado! Tu sesión ha sido procesada exitosamente.',
          sessionId: event.sessionId,
        ));
      } else {
        emit(PsychologyPaymentError(
          message: 'El pago no ha sido completado aún',
        ));
      }
    } catch (e) {
      emit(PsychologyPaymentError(
        message: 'Error verificando el pago: ${e.toString()}',
      ));
    }
  }
}