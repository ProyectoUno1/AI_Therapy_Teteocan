// lib/presentation/psychologist/bloc/dashboard_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<AppointmentModel> todaySessions; 
  final List<AppointmentModel> recentSessions; 
  final List<AppointmentModel> allMonthSessions; 
  final int monthSessions;
  final int activePatients;
  final int weekSessions;
  final double occupancyRate;
  final String? errorMessage;

  const DashboardState({
    required this.status,
    required this.todaySessions,
    required this.recentSessions,
    required this.allMonthSessions,
    required this.monthSessions,
    required this.activePatients,
    required this.weekSessions,
    required this.occupancyRate,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    List<AppointmentModel>? todaySessions,
    List<AppointmentModel>? recentSessions,
    List<AppointmentModel>? allMonthSessions,
    int? monthSessions,
    int? activePatients,
    int? weekSessions,
    double? occupancyRate,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      todaySessions: todaySessions ?? this.todaySessions,
      recentSessions: recentSessions ?? this.recentSessions,
      allMonthSessions: allMonthSessions ?? this.allMonthSessions,
      monthSessions: monthSessions ?? this.monthSessions,
      activePatients: activePatients ?? this.activePatients,
      weekSessions: weekSessions ?? this.weekSessions,
      occupancyRate: occupancyRate ?? this.occupancyRate,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todaySessions,
        recentSessions,
        allMonthSessions,
        monthSessions,
        activePatients,
        weekSessions,
        occupancyRate,
        errorMessage,
      ];
}