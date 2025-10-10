// lib/data/repositories/dashboard_repository.dart

import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/core/services/appointment_service.dart';

class DashboardRepository {
  final AppointmentService _appointmentService;

  DashboardRepository({AppointmentService? appointmentService})
      : _appointmentService = appointmentService ?? AppointmentService();

  Future<Map<String, dynamic>> getDashboardData(String psychologistId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final allAppointments = await _appointmentService.getAppointments(
        role: 'psychologist',
      );

      final todayAppointments = allAppointments
          .where((apt) =>
              (apt.status == AppointmentStatus.confirmed ||
                  apt.status == AppointmentStatus.in_progress) &&
              apt.scheduledDateTime.year == today.year &&
              apt.scheduledDateTime.month == today.month &&
              apt.scheduledDateTime.day == today.day)
          .toList()
        ..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

      final monthAppointments = allAppointments
          .where((apt) =>
              (apt.status == AppointmentStatus.confirmed ||
                  apt.status == AppointmentStatus.in_progress ||
                  apt.status == AppointmentStatus.completed) &&
              apt.scheduledDateTime.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              apt.scheduledDateTime.isBefore(endOfMonth.add(const Duration(days: 1))))
          .toList();

      final recentAppointments = allAppointments
          .where((apt) =>
              apt.status == AppointmentStatus.completed ||
              apt.status == AppointmentStatus.rated)
          .toList()
        ..sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));

      final recentAppointmentsList = recentAppointments.take(5).toList();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));

      final weekAppointments = allAppointments
          .where((apt) =>
              apt.scheduledDateTime.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              apt.scheduledDateTime.isBefore(endOfWeek.add(const Duration(seconds: 1))))
          .length;

      final activePatientIds = allAppointments
          .where((apt) =>
              apt.status == AppointmentStatus.confirmed ||
              apt.status == AppointmentStatus.in_progress)
          .map((apt) => apt.patientId)
          .toSet()
          .length;

      final occupancyRate = (weekAppointments / 42).clamp(0.0, 1.0);

      return {
        'todaySessions': todayAppointments, 
        'recentSessions': recentAppointmentsList,
        'allMonthSessions': monthAppointments, 
        'monthSessions': monthAppointments.length, 
        'weekSessions': weekAppointments,
        'activePatients': activePatientIds,
        'occupancyRate': occupancyRate,
      };
    } catch (e) {
      throw Exception('Error al cargar datos del dashboard: $e');
    }
  }
}