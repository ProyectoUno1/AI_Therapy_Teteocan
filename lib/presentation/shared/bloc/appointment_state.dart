// lib/presentation/shared/bloc/appointment_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';

enum AppointmentStateStatus {
  initial,
  loading,
  loaded,
  booking,
  booked,
  confirming,
  confirmed,
  cancelling,
  cancelled,
  rescheduling,
  rescheduled,
  completing,
  completed,
  error,
}

class TimeSlot {
  final String time;
  final DateTime dateTime;
  final bool isAvailable;
  final String? reason;

  const TimeSlot({
    required this.time,
    required this.dateTime,
    this.isAvailable = true,
    this.reason,
  });

  TimeSlot copyWith({
    String? time,
    DateTime? dateTime,
    bool? isAvailable,
    String? reason,
  }) {
    return TimeSlot(
      time: time ?? this.time,
      dateTime: dateTime ?? this.dateTime,
      isAvailable: isAvailable ?? this.isAvailable,
      reason: reason ?? this.reason,
    );
  }
}

class AppointmentState extends Equatable {
  final AppointmentStateStatus status;
  final List<AppointmentModel> appointments;
  final List<AppointmentModel> pendingAppointments;
  final List<AppointmentModel> upcomingAppointments;
  final List<AppointmentModel> pastAppointments;
  final List<TimeSlot> availableTimeSlots;
  final AppointmentModel? selectedAppointment;
  final String? errorMessage;
  final String? successMessage;
  final bool isLoading;

  const AppointmentState({
    this.status = AppointmentStateStatus.initial,
    this.appointments = const [],
    this.pendingAppointments = const [],
    this.upcomingAppointments = const [],
    this.pastAppointments = const [],
    this.availableTimeSlots = const [],
    this.selectedAppointment,
    this.errorMessage,
    this.successMessage,
    this.isLoading = false,
  });

  AppointmentState copyWith({
    AppointmentStateStatus? status,
    List<AppointmentModel>? appointments,
    List<AppointmentModel>? pendingAppointments,
    List<AppointmentModel>? upcomingAppointments,
    List<AppointmentModel>? pastAppointments,
    List<TimeSlot>? availableTimeSlots,
    AppointmentModel? selectedAppointment,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
  }) {
    return AppointmentState(
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      pendingAppointments: pendingAppointments ?? this.pendingAppointments,
      upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
      pastAppointments: pastAppointments ?? this.pastAppointments,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      selectedAppointment: selectedAppointment ?? this.selectedAppointment,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Factory constructors para estados comunes
  factory AppointmentState.initial() {
    return const AppointmentState();
  }

  factory AppointmentState.loading() {
    return const AppointmentState(
      status: AppointmentStateStatus.loading,
      isLoading: true,
    );
  }

  factory AppointmentState.loaded({
    required List<AppointmentModel> appointments,
  }) {
    final now = DateTime.now();

    // Filtrar citas pendientes (necesitan confirmación del psicólogo)
    final pending = appointments
        .where((apt) => apt.status == AppointmentStatus.pending)
        .toList();

    // Filtrar citas próximas (confirmadas y futuras)
    final upcoming = appointments
        .where(
          (apt) =>
              apt.status == AppointmentStatus.confirmed &&
              apt.scheduledDateTime.isAfter(now),
        )
        .toList();

    // Filtrar citas pasadas (completadas o pasadas)
    final past = appointments
        .where(
          (apt) =>
              apt.status == AppointmentStatus.completed ||
              (apt.scheduledDateTime.isBefore(now) &&
                  apt.status != AppointmentStatus.pending),
        )
        .toList();

    return AppointmentState(
      status: AppointmentStateStatus.loaded,
      appointments: appointments,
      pendingAppointments: pending,
      upcomingAppointments: upcoming,
      pastAppointments: past,
      isLoading: false,
    );
  }

  factory AppointmentState.booking() {
    return const AppointmentState(
      status: AppointmentStateStatus.booking,
      isLoading: true,
    );
  }

  factory AppointmentState.booked({
    required AppointmentModel appointment,
    String? successMessage,
  }) {
    return AppointmentState(
      status: AppointmentStateStatus.booked,
      selectedAppointment: appointment,
      successMessage: successMessage ?? 'Cita agendada exitosamente',
      isLoading: false,
    );
  }

  factory AppointmentState.confirming() {
    return const AppointmentState(
      status: AppointmentStateStatus.confirming,
      isLoading: true,
    );
  }

  factory AppointmentState.confirmed({
    required AppointmentModel appointment,
    String? successMessage,
  }) {
    return AppointmentState(
      status: AppointmentStateStatus.confirmed,
      selectedAppointment: appointment,
      successMessage: successMessage ?? 'Cita confirmada exitosamente',
      isLoading: false,
    );
  }

  factory AppointmentState.cancelling() {
    return const AppointmentState(
      status: AppointmentStateStatus.cancelling,
      isLoading: true,
    );
  }

  factory AppointmentState.cancelled({
    required AppointmentModel appointment,
    String? successMessage,
  }) {
    return AppointmentState(
      status: AppointmentStateStatus.cancelled,
      selectedAppointment: appointment,
      successMessage: successMessage ?? 'Cita cancelada exitosamente',
      isLoading: false,
    );
  }

  factory AppointmentState.error({required String errorMessage}) {
    return AppointmentState(
      status: AppointmentStateStatus.error,
      errorMessage: errorMessage,
      isLoading: false,
    );
  }

  factory AppointmentState.timeSlotsLoaded({
    required List<TimeSlot> timeSlots,
  }) {
    return AppointmentState(
      status: AppointmentStateStatus.loaded,
      availableTimeSlots: timeSlots,
      isLoading: false,
    );
  }

  // Getters de utilidad
  bool get isInitial => status == AppointmentStateStatus.initial;
  bool get isLoadingState => status == AppointmentStateStatus.loading;
  bool get isLoaded => status == AppointmentStateStatus.loaded;
  bool get isBooking => status == AppointmentStateStatus.booking;
  bool get isBooked => status == AppointmentStateStatus.booked;
  bool get isConfirming => status == AppointmentStateStatus.confirming;
  bool get isConfirmed => status == AppointmentStateStatus.confirmed;
  bool get isCancelling => status == AppointmentStateStatus.cancelling;
  bool get isCancelled => status == AppointmentStateStatus.cancelled;
  bool get isError => status == AppointmentStateStatus.error;

  bool get hasAppointments => appointments.isNotEmpty;
  bool get hasPendingAppointments => pendingAppointments.isNotEmpty;
  bool get hasUpcomingAppointments => upcomingAppointments.isNotEmpty;
  bool get hasPastAppointments => pastAppointments.isNotEmpty;
  bool get hasAvailableTimeSlots => availableTimeSlots.isNotEmpty;

  int get totalAppointments => appointments.length;
  int get pendingCount => pendingAppointments.length;
  int get upcomingCount => upcomingAppointments.length;
  int get pastCount => pastAppointments.length;

  @override
  List<Object?> get props => [
    status,
    appointments,
    pendingAppointments,
    upcomingAppointments,
    pastAppointments,
    availableTimeSlots,
    selectedAppointment,
    errorMessage,
    successMessage,
    isLoading,
  ];
}
