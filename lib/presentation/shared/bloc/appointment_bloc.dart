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
    on<LoadSampleAppointmentsEvent>(_onLoadSampleAppointments);
    on<RateAppointmentEvent>(_onRateAppointment);
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

      final upcomingAppointments = allAppointments
          .where(
            (apt) =>
                (apt.status == AppointmentStatus.confirmed ||
                    apt.status == AppointmentStatus.rescheduled) &&
                apt.scheduledDateTime.isAfter(now),
          )
          .toList();

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.rated ||
                apt.status == AppointmentStatus.cancelled ||
                (apt.status == AppointmentStatus.confirmed &&
                    apt.scheduledDateTime.isBefore(now)),
          )
          .toList();

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.loaded,
            pendingAppointments: pendingAppointments,
            upcomingAppointments: upcomingAppointments,
            pastAppointments: pastAppointments,
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
        scheduledDateTime: event.scheduledDateTime,
        type: event.type,
        notes: event.notes,
      );

      if (isClosed) return;

      // ACTUALIZAR TODAS LAS LISTAS DE CITAS
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

      await Future.delayed(const Duration(milliseconds: 50));

      emit(state.copyWith(status: AppointmentStateStatus.confirming));

      await _appointmentService.confirmAppointment(
        appointmentId: event.appointmentId,
        psychologistNotes: event.psychologistNotes,
        meetingLink: event.meetingLink,
      );

      if (isClosed) return;

      // RECARGAR todas las citas después de confirmar
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

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.rated ||
                apt.status == AppointmentStatus.cancelled ||
                (apt.status == AppointmentStatus.confirmed &&
                    apt.scheduledDateTime.isBefore(now)),
          )
          .toList();

      final confirmedAppointment = allAppointments.firstWhere(
        (apt) => apt.id == event.appointmentId,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.confirmed,
            pendingAppointments: pendingAppointments,
            upcomingAppointments: upcomingAppointments,
            pastAppointments: pastAppointments,
            appointments: allAppointments,
            message: 'Cita confirmada exitosamente',
            selectedAppointment: confirmedAppointment,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        await Future.delayed(const Duration(milliseconds: 100));
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
      await Future.delayed(const Duration(milliseconds: 50));
      emit(state.copyWith(status: AppointmentStateStatus.cancelling));

      // 1. Ejecutar la operación de Firebase
      await _appointmentService.cancelAppointment(
        appointmentId: event.appointmentId,
        reason: event.reason,
      );

      if (isClosed) return;

      // 2. RECARGAR TODAS LAS CITAS para asegurar consistencia
      final allAppointments = await _appointmentService.getAppointments(
        role: 'psychologist',
      );

      if (isClosed) return;

      final now = DateTime.now();

      // 3. RECALCULAR todas las listas con los nuevos datos
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

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.rated ||
                apt.status == AppointmentStatus.cancelled ||
                (apt.status == AppointmentStatus.confirmed &&
                    apt.scheduledDateTime.isBefore(now)),
          )
          .toList();

      // 4. Buscar la cita cancelada para selectedAppointment
      final cancelledAppointment = allAppointments.firstWhere(
        (apt) => apt.id == event.appointmentId,
      );
      // Pequeño delay antes de emitir el estado final
      await Future.delayed(const Duration(milliseconds: 100));

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.cancelled,
            pendingAppointments: pendingAppointments,
            upcomingAppointments: upcomingAppointments,
            pastAppointments: pastAppointments,
            appointments: allAppointments,
            message: 'Cita cancelada exitosamente',
            selectedAppointment: cancelledAppointment,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        await Future.delayed(const Duration(milliseconds: 100));
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

      // Actualizar la lista localmente
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

      if (startDate.isBefore(DateTime.now())) {
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

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.rated ||
                apt.status == AppointmentStatus.cancelled ||
                (apt.status == AppointmentStatus.confirmed &&
                    apt.scheduledDateTime.isBefore(now)),
          )
          .toList();

      emit(
        state.copyWith(
          pendingAppointments: pendingAppointments,
          upcomingAppointments: upcomingAppointments,
          pastAppointments: pastAppointments,
          appointments: allAppointments,
        ),
      );
    } catch (e) {
      log('Error al recargar citas: $e', name: 'AppointmentBloc');
    }
  }

  // Getter para combinar todas las listas de citas
  List<AppointmentModel> get allAppointments {
    final List<AppointmentModel> all = [];
    if (state.pendingAppointments.isNotEmpty)
      all.addAll(state.pendingAppointments);
    if (state.upcomingAppointments.isNotEmpty)
      all.addAll(state.upcomingAppointments);
    if (state.pastAppointments.isNotEmpty) all.addAll(state.pastAppointments);
    return all;
  }

  Future<void> _onLoadSampleAppointments(
    LoadSampleAppointmentsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.loading));

      final allAppointments = event.appointments;
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

      final pastAppointments = allAppointments
          .where(
            (apt) =>
                apt.status == AppointmentStatus.completed ||
                apt.status == AppointmentStatus.rated ||
                (apt.scheduledDateTime.isBefore(now) &&
                    apt.status != AppointmentStatus.pending),
          )
          .toList();

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AppointmentStateStatus.success,
          pendingAppointments: pendingAppointments,
          upcomingAppointments: upcomingAppointments,
          pastAppointments: pastAppointments,
          errorMessage: null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AppointmentStateStatus.error,
          errorMessage: 'Error al cargar las citas de prueba: $e',
        ),
      );
    }
  }

  // RATING APPOINTMENT HANDLER - Preparado para backend
  Future<void> _onRateAppointment(
    RateAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      if (isClosed) return;
      emit(state.copyWith(status: AppointmentStateStatus.loading));

      // Buscar la cita en todas las listas
      AppointmentModel? appointmentToRate;
      List<AppointmentModel> updatedPending = List.from(
        state.pendingAppointments,
      );
      List<AppointmentModel> updatedUpcoming = List.from(
        state.upcomingAppointments,
      );
      List<AppointmentModel> updatedPast = List.from(state.pastAppointments);

      // Buscar en citas completadas (pasadas)
      for (int i = 0; i < updatedPast.length; i++) {
        if (updatedPast[i].id == event.appointmentId) {
          appointmentToRate = updatedPast[i];

          // Actualizar la cita con rating y cambiar estado a 'rated'
          final ratedAppointment = appointmentToRate.copyWith(
            rating: event.rating,
            ratingComment: event.comment,
            ratedAt: DateTime.now(),
            status: AppointmentStatus.rated,
          );

          updatedPast[i] = ratedAppointment;
          break;
        }
      }

      if (appointmentToRate == null) {
        emit(
          state.copyWith(
            status: AppointmentStateStatus.error,
            errorMessage: 'Cita no encontrada',
          ),
        );
        return;
      }

      // TODO: Cuando esté el backend, aquí se haría:
      // await _appointmentService.rateAppointment(
      //   appointmentId: event.appointmentId,
      //   rating: event.rating,
      //   comment: event.comment,
      // );

      if (isClosed) return;

      emit(
        state.copyWith(
          status: AppointmentStateStatus.success,
          pendingAppointments: updatedPending,
          upcomingAppointments: updatedUpcoming,
          pastAppointments: updatedPast,
          successMessage: 'Calificación enviada exitosamente',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AppointmentStateStatus.error,
          errorMessage: 'Error al enviar calificación: $e',
        ),
      );
    }
  }
}
