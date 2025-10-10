// lib/presentation/payment_history/bloc/payment_history_event.dart
part of 'payment_history_bloc.dart';

abstract class PaymentHistoryEvent {}

class LoadPaymentHistory extends PaymentHistoryEvent {}

class LoadPaymentDetails extends PaymentHistoryEvent {
  final String paymentId;

  LoadPaymentDetails(this.paymentId);
}