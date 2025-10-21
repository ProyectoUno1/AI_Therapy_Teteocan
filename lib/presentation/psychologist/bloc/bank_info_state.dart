import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';
import 'package:ai_therapy_teteocan/data/models/payment_model.dart';

enum BankInfoStatus { initial, loading, success, error }

class BankInfoState {
  final BankInfoStatus status;
  final BankInfoModel? bankInfo;
  final List<PaymentModel> payments;
  final List<PaymentModel> filteredPayments;
  final String? selectedFilter; // 'all', 'completed', 'pending'
  final String? errorMessage;
  final double totalEarned;
  final double pendingAmount;

  BankInfoState({
    this.status = BankInfoStatus.initial,
    this.bankInfo,
    this.payments = const [],
    this.filteredPayments = const [],
    this.selectedFilter = 'all',
    this.errorMessage,
    this.totalEarned = 0.0,
    this.pendingAmount = 0.0,
  });

  BankInfoState copyWith({
    BankInfoStatus? status,
    BankInfoModel? bankInfo,
    List<PaymentModel>? payments,
    List<PaymentModel>? filteredPayments,
    String? selectedFilter,
    String? errorMessage,
    double? totalEarned,
    double? pendingAmount,
  }) {
    return BankInfoState(
      status: status ?? this.status,
      bankInfo: bankInfo ?? this.bankInfo,
      payments: payments ?? this.payments,
      filteredPayments: filteredPayments ?? this.filteredPayments,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      errorMessage: errorMessage,
      totalEarned: totalEarned ?? this.totalEarned,
      pendingAmount: pendingAmount ?? this.pendingAmount,
    );
  }
}