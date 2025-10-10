// lib/presentation/psychologist/bloc/dashboard_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository(),
        super(const DashboardState(
          status: DashboardStatus.initial,
          todaySessions: [],
          recentSessions: [],
          allMonthSessions: [],
          monthSessions: 0, 
          weekSessions: 0,
          activePatients: 0,
          occupancyRate: 0.0,
        )) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _repository.getDashboardData(event.psychologistId);
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        todaySessions: data['todaySessions'],
        recentSessions: data['recentSessions'],
        allMonthSessions: data['allMonthSessions'], 
        monthSessions: data['monthSessions'], 
        weekSessions: data['weekSessions'],
        activePatients: data['activePatients'],
        occupancyRate: data['occupancyRate'],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final data = await _repository.getDashboardData(event.psychologistId);
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        todaySessions: data['todaySessions'],
        recentSessions: data['recentSessions'],
        allMonthSessions: data['allMonthSessions'],
        monthSessions: data['monthSessions'], 
        weekSessions: data['weekSessions'],
        activePatients: data['activePatients'],
        occupancyRate: data['occupancyRate'],
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}