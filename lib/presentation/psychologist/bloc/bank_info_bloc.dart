import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/bank_info_repository.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/bank_info_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/bank_info_state.dart';

class BankInfoBloc extends Bloc<BankInfoEvent, BankInfoState> {
  final BankInfoRepository repository;

  BankInfoBloc({required this.repository}) : super(const BankInfoState()) {
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
      print('🔄 Cargando información bancaria para: ${event.psychologistId}');
      final bankInfo = await repository.getBankInfo(event.psychologistId);
      
      if (bankInfo != null) {
        print('✅ Información bancaria cargada correctamente');
        emit(state.copyWith(
          status: BankInfoStatus.success,
          bankInfo: bankInfo,
        ));
      } else {
        print('⚠️ No se encontró información bancaria');
        emit(state.copyWith(
          status: BankInfoStatus.success,
          bankInfo: null,
        ));
      }
    } catch (e) {
      print('❌ Error cargando información bancaria: $e');
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
      print('💾 Guardando información bancaria...');
      final bankInfo = await repository.saveBankInfo(event.bankInfo);
      
      print('✅ Información bancaria guardada correctamente');
      emit(state.copyWith(
        status: BankInfoStatus.success,
        bankInfo: bankInfo,
      ));
    } catch (e) {
      print('❌ Error guardando información bancaria: $e');
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
      print('🔄 Actualizando información bancaria...');
      final bankInfo = await repository.updateBankInfo(event.bankInfo);
      
      print('✅ Información bancaria actualizada correctamente');
      emit(state.copyWith(
        status: BankInfoStatus.success,
        bankInfo: bankInfo,
      ));
    } catch (e) {
      print('❌ Error actualizando información bancaria: $e');
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
      // Cargar todos los pagos
      final payments = await repository.getPaymentHistory(event.psychologistId);
      
      // Calcular totales
      double totalEarned = 0;
      double pendingAmount = 0;

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
        currentFilter: 'all',
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
    
    List<dynamic> filteredPaymentsList;
    
    if (event.status == 'all') {
      filteredPaymentsList = state.payments;
    } else {
      filteredPaymentsList = state.payments
          .where((payment) => payment.status == event.status)
          .toList();
    }

    emit(state.copyWith(
      filteredPayments: filteredPaymentsList.cast(),
      currentFilter: event.status,
    ));
  }
}