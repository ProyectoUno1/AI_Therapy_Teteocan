// lib/presentation/payment_history/bloc/payment_history_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/payment_history_repository.dart';
import 'package:ai_therapy_teteocan/data/models/payment_history_model.dart';

part 'payment_history_event.dart';
part 'payment_history_state.dart';

class PaymentHistoryBloc extends Bloc<PaymentHistoryEvent, PaymentHistoryState> {
  final PaymentHistoryRepository _repository;

  PaymentHistoryBloc(this._repository) : super(PaymentHistoryInitial()) {
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<LoadPaymentDetails>(_onLoadPaymentDetails);
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentHistoryState> emit,
  ) async {
    emit(PaymentHistoryLoading());
    try {
      final payments = await _repository.getPaymentHistory(); 
      emit(PaymentHistoryLoaded(payments: payments));
    } catch (e) {
      emit(PaymentHistoryError(message: e.toString()));
    }
  }
  
  Future<void> _onLoadPaymentDetails(
    LoadPaymentDetails event,
    Emitter<PaymentHistoryState> emit,
  ) async {
    emit(PaymentDetailsLoading());
    try {
      final paymentDetails = await _repository.getPaymentDetails(event.paymentId);
      if (paymentDetails != null) {
        emit(PaymentDetailsLoaded(paymentDetails: paymentDetails));
      } else {
        emit(PaymentHistoryError(message: 'Detalles del pago no encontrados.'));
      }
    } catch (e) {
      emit(PaymentHistoryError(message: e.toString()));
    }
  }
}