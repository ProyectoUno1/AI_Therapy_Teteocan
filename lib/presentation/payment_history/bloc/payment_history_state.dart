// lib/presentation/payment_history/bloc/payment_history_state.dart
part of 'payment_history_bloc.dart';

abstract class PaymentHistoryState {}

class PaymentHistoryInitial extends PaymentHistoryState {}

class PaymentHistoryLoading extends PaymentHistoryState {}

class PaymentHistoryLoaded extends PaymentHistoryState {
  final List<PaymentRecord> payments;

  PaymentHistoryLoaded({required this.payments});
}

class PaymentDetailsLoading extends PaymentHistoryState {}

class PaymentDetailsLoaded extends PaymentHistoryState {
  final PaymentDetails paymentDetails;

  PaymentDetailsLoaded({required this.paymentDetails});
}

class PaymentHistoryError extends PaymentHistoryState {
  final String message;

  PaymentHistoryError({required this.message});
}