import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/core/services/appointment_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentService _appointmentService;

  AppointmentBloc({AppointmentService? appointmentService})
    : _appointmentService = appointmentService ?? AppointmentService(),
      super(AppointmentState.initial()) {
    on<LoadAppointmentsEvent>(_onLoadAppointments);
    on<BookAppointmentEvent>(_onBookAppointment);
    on<ConfirmAppointmentEvent>(_onConfirmAppointment);
    on<CancelAppointmentEvent>(_onCancelAppointment);
    on<RescheduleAppointmentEvent>(_onRescheduleAppointment);
    on<CompleteAppointmentEvent>(_onCompleteAppointment);
    on<LoadAvailableTimeSlotsEvent>(_onLoadAvailableTimeSlots);
    on<GetAppointmentDetailsEvent>(_onGetAppointmentDetails);
    on<RateAppointmentEvent>(_onRateAppointment);
    on<StartAppointmentSessionEvent>(_onStartAppointmentSession);
    on<CompleteAppointmentSessionEvent>(_onCompleteAppointmentSession);
  }

  Future<void> _onLoadAppointments(
    LoadAppointmentsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.loading));

      final allAppointments = await _appointmentService.getAppointments(
        role: event.isForPsychologist ? 'psychologist' : 'patient',
      );

      if (isClosed) return;

      final now = DateTime.now();

      final pendingAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.pending)
          .toList();

      final inProgressAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.in_progress)
          .toList();

      final upcomingAppointments = allAppointments
          .where((apt) =>
              (apt.status == AppointmentStatus.confirmed ||
                  apt.status == AppointmentStatus.rescheduled) &&
              apt.scheduledDateTime.isAfter(now))
          .toList();

      final pastAppointments = allAppointments
          .where((apt) =>
              apt.status == AppointmentStatus.completed ||
              apt.status == AppointmentStatus.cancelled ||
              apt.status == AppointmentStatus.rated ||
              apt.status == AppointmentStatus.refunded ||
              ((apt.status == AppointmentStatus.confirmed ||
                      apt.status == AppointmentStatus.rescheduled) &&
                  apt.scheduledDateTime.isBefore(now)))
          .toList();

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.loaded,
            pendingAppointments: pendingAppointments,
            inProgressAppointments: inProgressAppointments,
            upcomingAppointments: upcomingAppointments,
            pastAppointments: pastAppointments,
            appointments: allAppointments,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al cargar las citas: $e',
          ),
        );
      }
    }
  }

  Future<void> _onBookAppointment(
    BookAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.booking));

      final appointment = await _appointmentService.createAppointment(
        psychologistId: event.psychologistId,
        patientId: event.patientId,
        scheduledDateTime: event.scheduledDateTime,
        type: event.type,
        notes: event.notes,
      );

      if (isClosed) return;
      final updatedPendingList = List<AppointmentModel>.from(
        state.pendingAppointments,
      )..add(appointment);

      final allAppointments = [...state.appointments, appointment];

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.booked,
            message: 'Cita agendada exitosamente',
            appointments: allAppointments,
            pendingAppointments: updatedPendingList,
            selectedAppointment: appointment,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al agendar cita: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onConfirmAppointment(
    ConfirmAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.confirming));

      // Confirmar la cita
      await _appointmentService.confirmAppointment(
        appointmentId: event.appointmentId,
        psychologistNotes: event.psychologistNotes,
        meetingLink: event.meetingLink,
      );

      if (isClosed) return;
      final allAppointments = await _appointmentService.getAppointments(
        role: 'psychologist',
      );

      if (isClosed) return;

      final now = DateTime.now();

      final pendingAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.pending)
          .toList();

      final upcomingAppointments = allAppointments
          .where(
            (apt) =>
                (apt.status == AppointmentStatus.confirmed ||
                    apt.status == AppointmentStatus.rescheduled) &&
                apt.scheduledDateTime.isAfter(now),
          )
          .toList();

      final inProgressAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.in_progress)
          .toList();

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.cancelled ||
                apt.status == AppointmentStatus.rated ||
                apt.status == AppointmentStatus.refunded ||
                (apt.status == AppointmentStatus.confirmed &&
                    apt.scheduledDateTime.isBefore(now)),
          )
          .toList();

      final confirmedAppointment = allAppointments.firstWhere(
        (apt) => apt.id == event.appointmentId,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.confirmed,
            pendingAppointments: pendingAppointments,
            upcomingAppointments: upcomingAppointments,
            inProgressAppointments: inProgressAppointments,
            pastAppointments: pastAppointments,
            appointments: allAppointments,
            message: 'Cita confirmada exitosamente',
            selectedAppointment: confirmedAppointment,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al confirmar la cita: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onCancelAppointment(
    CancelAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.cancelling));

      // Cancelar la cita
      await _appointmentService.cancelAppointment(
        appointmentId: event.appointmentId,
        reason: event.reason,
      );

      if (isClosed) return;
      final allAppointments = await _appointmentService.getAppointments(
        role: 'psychologist',
      );

      if (isClosed) return;

      final now = DateTime.now();

      final pendingAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.pending)
          .toList();

      final upcomingAppointments = allAppointments
          .where(
            (apt) =>
                (apt.status == AppointmentStatus.confirmed ||
                    apt.status == AppointmentStatus.rescheduled) &&
                apt.scheduledDateTime.isAfter(now),
          )
          .toList();

      final inProgressAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.in_progress)
          .toList();

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.cancelled ||
                apt.status == AppointmentStatus.rated ||
                apt.status == AppointmentStatus.refunded ||
                (apt.status == AppointmentStatus.confirmed &&
                    apt.scheduledDateTime.isBefore(now)),
          )
          .toList();

      final cancelledAppointment = allAppointments.firstWhere(
        (apt) => apt.id == event.appointmentId,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.cancelled,
            pendingAppointments: pendingAppointments,
            upcomingAppointments: upcomingAppointments,
            inProgressAppointments: inProgressAppointments,
            pastAppointments: pastAppointments,
            appointments: allAppointments,
            message: 'Cita cancelada exitosamente',
            selectedAppointment: cancelledAppointment,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al cancelar la cita: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onRescheduleAppointment(
    RescheduleAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.loading));
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Reagendamiento no implementado aún',
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al reagendar la cita: $e',
          ),
        );
      }
    }
  }

  Future<void> _onCompleteAppointment(
    CompleteAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.completing));

      await _appointmentService.completeAppointment(
        appointmentId: event.appointmentId,
        notes: event.notes,
      );

      if (isClosed) return;

      final completedAppointment = state.upcomingAppointments
          .firstWhere((apt) => apt.id == event.appointmentId)
          .copyWith(status: AppointmentStatus.completed);

      final updatedUpcomingList = List<AppointmentModel>.from(
        state.upcomingAppointments,
      )..removeWhere((apt) => apt.id == event.appointmentId);
      final updatedPastList = List<AppointmentModel>.from(
        state.pastAppointments,
      )..add(completedAppointment);

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.success,
            upcomingAppointments: updatedUpcomingList,
            pastAppointments: updatedPastList,
            message: 'Cita completada exitosamente',
            selectedAppointment: completedAppointment,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al completar la cita: $e',
          ),
        );
      }
    }
  }

  Future<void> _onLoadAvailableTimeSlots(
    LoadAvailableTimeSlotsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: AppointmentStateStatus.loading,
          availableTimeSlots: [],
        ),
      );

      final psychologistId = event.psychologistId;
      final startDate = event.startDate;
      final endDate = event.endDate;

      if (psychologistId == null || startDate == null || endDate == null) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AppointmentStateStatus.error,
              errorMessage: 'Datos incompletos para cargar horarios',
            ),
          );
        }
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final normalizedStartDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      if (normalizedStartDate.isBefore(today)) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: AppointmentStateStatus.error,
              errorMessage: 'No se pueden cargar horarios para fechas pasadas',
            ),
          );
        }
        return;
      }
      final slots = await _appointmentService.getAvailableTimeSlots(
        psychologistId: psychologistId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.loaded,
            availableTimeSlots: slots,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage:
                'Error al cargar horarios disponibles: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onGetAppointmentDetails(
    GetAppointmentDetailsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      final appointment = allAppointments.firstWhere(
        (apt) => apt.id == event.appointmentId,
        orElse: () => throw Exception('Cita no encontrada'),
      );

      if (!isClosed) {
        emit(state.copyWith(selectedAppointment: appointment));
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Cita no encontrada',
          ),
        );
      }
    }
  }

  Future<void> _reloadAppointments(Emitter<AppointmentState> emit) async {
    try {
      final allAppointments = await _appointmentService.getAppointments(
        role: 'psychologist',
      );

      final now = DateTime.now();

      final pendingAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.pending)
          .toList();

      final upcomingAppointments = allAppointments
          .where(
            (apt) =>
                (apt.status == AppointmentStatus.confirmed ||
                    apt.status == AppointmentStatus.rescheduled) &&
                apt.scheduledDateTime.isAfter(now),
          )
          .toList();

      final inProgressAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.in_progress)
          .toList();

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.cancelled ||
                apt.status == AppointmentStatus.rated ||
                apt.status == AppointmentStatus.refunded ||
                (apt.status == AppointmentStatus.confirmed &&
                    apt.scheduledDateTime.isBefore(now)),
          )
          .toList();

      emit(
        state.copyWith(
          pendingAppointments: pendingAppointments,
          upcomingAppointments: upcomingAppointments,
          inProgressAppointments: inProgressAppointments,
          pastAppointments: pastAppointments,
          appointments: allAppointments,
        ),
      );
    } catch (e) {
      log('Error al recargar citas: $e', name: 'AppointmentBloc');
    }
  }

  List<AppointmentModel> get allAppointments {
    final List<AppointmentModel> all = [];
    if (state.pendingAppointments.isNotEmpty)
      all.addAll(state.pendingAppointments);
    if (state.upcomingAppointments.isNotEmpty)
      all.addAll(state.upcomingAppointments);
    if (state.inProgressAppointments.isNotEmpty)
      all.addAll(state.inProgressAppointments);
    if (state.pastAppointments.isNotEmpty) all.addAll(state.pastAppointments);
    return all;
  }

  Future<void> _onRateAppointment(
    RateAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: AppointmentStateStatus.loading));

      await _appointmentService.rateAppointment(
        appointmentId: event.appointmentId,
        rating: event.rating,
        comment: event.comment,
      );

      final allAppointments = await _appointmentService.getAppointments(
        role: 'patient',
      );

      final now = DateTime.now();
      final pendingAppointments = allAppointments
          .where((apt) => apt.status == AppointmentStatus.pending)
          .toList();
      final upcomingAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.confirmed &&
                apt.scheduledDateTime.isAfter(now),
          )
          .toList();
      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.rated,
          )
          .toList();

      emit(
        state.copyWith(
          status: AppointmentStateStatus.success,
          message: 'Calificación enviada exitosamente',
          pendingAppointments: pendingAppointments,
          upcomingAppointments: upcomingAppointments,
          pastAppointments: pastAppointments,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AppointmentStateStatus.error,
          errorMessage: 'Error al calificar: $e',
        ),
      );
    }
  }

  Future<void> _onStartAppointmentSession(
    StartAppointmentSessionEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.startingSession));

      await _appointmentService.startAppointmentSession(
        appointmentId: event.appointmentId,
      );

      if (isClosed) return;

      // Recargar todas las citas
      await _reloadAppointments(emit);

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.sessionStarted,
            message: 'Sesión iniciada exitosamente',
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al iniciar la sesión: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onCompleteAppointmentSession(
    CompleteAppointmentSessionEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.completingSession));

      await _appointmentService.completeAppointmentSession(
        appointmentId: event.appointmentId,
        notes: event.notes,
      );

      if (isClosed) return;

      // Recargar todas las citas
      await _reloadAppointments(emit);

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.sessionCompleted,
            message: 'Sesión completada exitosamente',
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Error al completar la sesión: ${e.toString()}',
          ),
        );
      }
    }
  }
}