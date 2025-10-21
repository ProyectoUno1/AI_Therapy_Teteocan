import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/bank_info_repository.dart';
import 'package:ai_therapy_teteocan/data/models/payment_model.dart';
import 'bank_info_event.dart';
import 'bank_info_state.dart';


class BankInfoBloc extends Bloc<BankInfoEvent, BankInfoState> {
  final BankInfoRepository repository;

  BankInfoBloc({required this.repository}) : super(BankInfoState()) {
    on<LoadBankInfo>(_onLoadBankInfo);
    on<SaveBankInfo>(_onSaveBankInfo);
    on<UpdateBankInfo>(_onUpdateBankInfo);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<FilterPayments>(_onFilterPayments);
  }

  Future<void> _onLoadBankInfo(
    LoadBankInfo event,
    Emitter<BankInfoState> emit,
  ) async {
    emit(state.copyWith(status: BankInfoStatus.loading));
    try {
      final bankInfo = await repository.getBankInfo(event.psychologistId);
      emit(state.copyWith(
        status: BankInfoStatus.success,
        bankInfo: bankInfo,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BankInfoStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSaveBankInfo(
    SaveBankInfo event,
    Emitter<BankInfoState> emit,
  ) async {
    emit(state.copyWith(status: BankInfoStatus.loading));
    try {
      final savedBankInfo = await repository.saveBankInfo(event.bankInfo);
      emit(state.copyWith(
        status: BankInfoStatus.success,
        bankInfo: savedBankInfo,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BankInfoStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateBankInfo(
    UpdateBankInfo event,
    Emitter<BankInfoState> emit,
  ) async {
    emit(state.copyWith(status: BankInfoStatus.loading));
    try {
      final updatedBankInfo = await repository.updateBankInfo(event.bankInfo);
      emit(state.copyWith(
        status: BankInfoStatus.success,
        bankInfo: updatedBankInfo,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BankInfoStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<BankInfoState> emit,
  ) async {
    emit(state.copyWith(status: BankInfoStatus.loading));
    try {
      final payments = await repository.getPaymentHistory(
        event.psychologistId,
        status: event.status,
      );

      double totalEarned = 0.0;
      double pendingAmount = 0.0;

      for (var payment in payments) {
        if (payment.status == 'completed') {
          totalEarned += payment.amount;
        } else if (payment.status == 'pending') {
          pendingAmount += payment.amount;
        }
      }

      emit(state.copyWith(
        status: BankInfoStatus.success,
        payments: payments,
        filteredPayments: payments,
        totalEarned: totalEarned,
        pendingAmount: pendingAmount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BankInfoStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onFilterPayments(
    FilterPayments event,
    Emitter<BankInfoState> emit,
  ) {
    List<PaymentModel> filtered = state.payments;

    if (event.status != null && event.status != 'all') {
      filtered = state.payments
          .where((payment) => payment.status == event.status)
          .toList();
    }

    emit(state.copyWith(
      filteredPayments: filtered,
      selectedFilter: event.status ?? 'all',
    ));
  }
}