// lib/presentation/psychologist/bloc/bank_info_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';
import 'package:ai_therapy_teteocan/data/models/payment_model.dart';

enum BankInfoStatus { initial, loading, success, error }

class BankInfoState extends Equatable {
  final BankInfoStatus status;
  final BankInfoModel? bankInfo;
  final List<PaymentModel> payments;
  final List<PaymentModel> filteredPayments;
  final double totalEarned;
  final double pendingAmount;
  final String? errorMessage;
  final String currentFilter; // Agregado

  const BankInfoState({
    this.status = BankInfoStatus.initial,
    this.bankInfo,
    this.payments = const [],
    this.filteredPayments = const [],
    this.totalEarned = 0.0,
    this.pendingAmount = 0.0,
    this.errorMessage,
    this.currentFilter = 'all', // Agregado con valor por defecto
  });

  BankInfoState copyWith({
    BankInfoStatus? status,
    BankInfoModel? bankInfo,
    List<PaymentModel>? payments,
    List<PaymentModel>? filteredPayments,
    double? totalEarned,
    double? pendingAmount,
    String? errorMessage,
    String? currentFilter, // Agregado
  }) {
    return BankInfoState(
      status: status ?? this.status,
      bankInfo: bankInfo ?? this.bankInfo,
      payments: payments ?? this.payments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      totalEarned: totalEarned ?? this.totalEarned,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      errorMessage: errorMessage ?? this.errorMessage,
      currentFilter: currentFilter ?? this.currentFilter, // Agregado
    );
  }

  @override
  List<Object?> get props => [
        status,
        bankInfo,
        payments,
        filteredPayments,
        totalEarned,
        pendingAmount,
        errorMessage,
        currentFilter, // Agregado
      ];
}