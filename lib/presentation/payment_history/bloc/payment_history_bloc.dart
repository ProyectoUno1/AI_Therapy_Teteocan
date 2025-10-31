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
    print('🔄 Iniciando carga de historial de pagos...');
    emit(PaymentHistoryLoading());
    try {
      final payments = await _repository.getPaymentHistory();
      print('✅ Pagos obtenidos: ${payments.length}');
      
      if (payments.isEmpty) {
        print('⚠️ No se encontraron pagos');
      } else {
        for (var payment in payments) {
          print('💳 Pago: ${payment.id} - ${payment.description} - ${payment.formattedAmount}');
        }
      }
      
      emit(PaymentHistoryLoaded(payments: payments));
    } catch (e) {
      print('❌ Error en _onLoadPaymentHistory: $e');
      print('Stack trace: ${StackTrace.current}');
      emit(PaymentHistoryError(message: e.toString()));
    }
  }
  
  Future<void> _onLoadPaymentDetails(
    LoadPaymentDetails event,
    Emitter<PaymentHistoryState> emit,
  ) async {
    print('🔄 Cargando detalles del pago: ${event.paymentId}');
    emit(PaymentDetailsLoading());
    try {
      final paymentDetails = await _repository.getPaymentDetails(event.paymentId);
      if (paymentDetails != null) {
        print('✅ Detalles obtenidos para: ${event.paymentId}');
        emit(PaymentDetailsLoaded(paymentDetails: paymentDetails));
      } else {
        print('⚠️ No se encontraron detalles para: ${event.paymentId}');
        emit(PaymentHistoryError(message: 'Detalles del pago no encontrados.'));
      }
    } catch (e) {
      print('❌ Error en _onLoadPaymentDetails: $e');
      emit(PaymentHistoryError(message: e.toString()));
    }
  }
}