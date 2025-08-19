// lib/presentation/shared/bloc/appointment_bloc.dart

import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final _uuid = const Uuid();

  // Mock data para demostración - en producción vendrá del backend
  final List<AppointmentModel> _mockAppointments = [];

  AppointmentBloc() : super(AppointmentState.initial()) {
    on<LoadAppointmentsEvent>(_onLoadAppointments);
    on<BookAppointmentEvent>(_onBookAppointment);
    on<ConfirmAppointmentEvent>(_onConfirmAppointment);
    on<CancelAppointmentEvent>(_onCancelAppointment);
    on<RescheduleAppointmentEvent>(_onRescheduleAppointment);
    on<CompleteAppointmentEvent>(_onCompleteAppointment);
    on<LoadAvailableTimeSlotsEvent>(_onLoadAvailableTimeSlots);
    on<GetAppointmentDetailsEvent>(_onGetAppointmentDetails);
    on<LoadSampleAppointmentsEvent>(_onLoadSampleAppointments);

    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    // Cita pendiente de confirmación
    _mockAppointments.add(
      AppointmentModel(
        id: _uuid.v4(),
        patientId: 'patient_1',
        patientName: 'María García',
        patientEmail: 'maria.garcia@email.com',
        patientProfileUrl: 'https://via.placeholder.com/60',
        psychologistId: 'psychologist_1',
        psychologistName: 'Dr. Juan Pérez',
        psychologistSpecialty: 'Psicología Clínica',
        psychologistProfileUrl: 'https://via.placeholder.com/60',
        scheduledDateTime: now.add(const Duration(days: 2, hours: 10)),
        type: AppointmentType.online,
        status: AppointmentStatus.pending,
        price: 80.0,
        patientNotes: 'Primera consulta por ansiedad generalizada',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    );

    // Cita confirmada
    _mockAppointments.add(
      AppointmentModel(
        id: _uuid.v4(),
        patientId: 'patient_2',
        patientName: 'Carlos Rodríguez',
        patientEmail: 'carlos.rodriguez@email.com',
        psychologistId: 'psychologist_1',
        psychologistName: 'Dr. Juan Pérez',
        psychologistSpecialty: 'Psicología Clínica',
        scheduledDateTime: now.add(const Duration(days: 5, hours: 14)),
        type: AppointmentType.inPerson,
        status: AppointmentStatus.confirmed,
        price: 80.0,
        createdAt: now.subtract(const Duration(days: 1)),
        confirmedAt: now.subtract(const Duration(hours: 12)),
        meetingLink: 'https://meet.google.com/abc-defg-hij',
      ),
    );

    // Cita completada
    _mockAppointments.add(
      AppointmentModel(
        id: _uuid.v4(),
        patientId: 'patient_3',
        patientName: 'Ana Martínez',
        patientEmail: 'ana.martinez@email.com',
        psychologistId: 'psychologist_1',
        psychologistName: 'Dr. Juan Pérez',
        psychologistSpecialty: 'Psicología Clínica',
        scheduledDateTime: now.subtract(const Duration(days: 3)),
        type: AppointmentType.online,
        status: AppointmentStatus.completed,
        price: 80.0,
        createdAt: now.subtract(const Duration(days: 4)),
        confirmedAt: now.subtract(const Duration(days: 4, hours: 2)),
        completedAt: now.subtract(const Duration(days: 3)),
        psychologistNotes: 'Sesión productiva. Paciente muestra progreso.',
      ),
    );
  }

  Future<void> _onLoadAppointments(
    LoadAppointmentsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.loading());

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      // Filtrar citas según el usuario
      List<AppointmentModel> userAppointments;

      if (event.isForPsychologist) {
        userAppointments = _mockAppointments
            .where((apt) => apt.psychologistId == event.userId)
            .toList();
      } else {
        userAppointments = _mockAppointments
            .where((apt) => apt.patientId == event.userId)
            .toList();
      }

      // Ordenar por fecha
      userAppointments.sort(
        (a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime),
      );

      emit(AppointmentState.loaded(appointments: userAppointments));

      log(
        'Citas cargadas: ${userAppointments.length}',
        name: 'AppointmentBloc',
      );
    } catch (e) {
      log('Error al cargar citas: $e', name: 'AppointmentBloc');
      emit(
        AppointmentState.error(errorMessage: 'Error al cargar las citas: $e'),
      );
    }
  }

  Future<void> _onBookAppointment(
    BookAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.booking());

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 1200));

      // TODO: Obtener datos reales del psicólogo y paciente del backend
      // Por ahora usaremos datos mock

      final newAppointment = AppointmentModel(
        id: _uuid.v4(),
        patientId: 'current_patient_id', // Obtener del contexto de auth
        patientName: 'Usuario Actual',
        patientEmail: 'usuario@email.com',
        psychologistId: event.psychologistId,
        psychologistName: 'Dr. Seleccionado',
        psychologistSpecialty: 'Especialidad',
        scheduledDateTime: event.scheduledDateTime,
        type: event.type,
        status: AppointmentStatus.pending,
        price: 80.0, // Obtener del perfil del psicólogo
        patientNotes: event.notes,
        createdAt: DateTime.now(),
      );

      // Agregar a la lista mock
      _mockAppointments.add(newAppointment);

      emit(
        AppointmentState.booked(
          appointment: newAppointment,
          successMessage:
              'Cita agendada exitosamente. Esperando confirmación del psicólogo.',
        ),
      );

      log('Cita agendada: ${newAppointment.id}', name: 'AppointmentBloc');
    } catch (e) {
      log('Error al agendar cita: $e', name: 'AppointmentBloc');
      emit(
        AppointmentState.error(errorMessage: 'Error al agendar la cita: $e'),
      );
    }
  }

  Future<void> _onConfirmAppointment(
    ConfirmAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.confirming());

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      // Buscar y actualizar la cita
      final appointmentIndex = _mockAppointments.indexWhere(
        (apt) => apt.id == event.appointmentId,
      );

      if (appointmentIndex == -1) {
        throw Exception('Cita no encontrada');
      }

      final updatedAppointment = _mockAppointments[appointmentIndex].copyWith(
        status: AppointmentStatus.confirmed,
        confirmedAt: DateTime.now(),
        psychologistNotes: event.psychologistNotes,
        meetingLink: event.meetingLink,
      );

      _mockAppointments[appointmentIndex] = updatedAppointment;

      emit(
        AppointmentState.confirmed(
          appointment: updatedAppointment,
          successMessage: 'Cita confirmada exitosamente',
        ),
      );

      log('Cita confirmada: ${event.appointmentId}', name: 'AppointmentBloc');
    } catch (e) {
      log('Error al confirmar cita: $e', name: 'AppointmentBloc');
      emit(
        AppointmentState.error(errorMessage: 'Error al confirmar la cita: $e'),
      );
    }
  }

  Future<void> _onCancelAppointment(
    CancelAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.cancelling());

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      // Buscar y actualizar la cita
      final appointmentIndex = _mockAppointments.indexWhere(
        (apt) => apt.id == event.appointmentId,
      );

      if (appointmentIndex == -1) {
        throw Exception('Cita no encontrada');
      }

      final updatedAppointment = _mockAppointments[appointmentIndex].copyWith(
        status: AppointmentStatus.cancelled,
        cancelledAt: DateTime.now(),
        cancellationReason: event.reason,
      );

      _mockAppointments[appointmentIndex] = updatedAppointment;

      emit(
        AppointmentState.cancelled(
          appointment: updatedAppointment,
          successMessage: 'Cita cancelada exitosamente',
        ),
      );

      log('Cita cancelada: ${event.appointmentId}', name: 'AppointmentBloc');
    } catch (e) {
      log('Error al cancelar cita: $e', name: 'AppointmentBloc');
      emit(
        AppointmentState.error(errorMessage: 'Error al cancelar la cita: $e'),
      );
    }
  }

  Future<void> _onRescheduleAppointment(
    RescheduleAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.loading());

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      // Buscar y actualizar la cita
      final appointmentIndex = _mockAppointments.indexWhere(
        (apt) => apt.id == event.appointmentId,
      );

      if (appointmentIndex == -1) {
        throw Exception('Cita no encontrada');
      }

      final updatedAppointment = _mockAppointments[appointmentIndex].copyWith(
        scheduledDateTime: event.newDateTime,
        status: AppointmentStatus.rescheduled,
        notes: event.reason,
      );

      _mockAppointments[appointmentIndex] = updatedAppointment;

      emit(AppointmentState.loaded(appointments: _mockAppointments));

      log('Cita reagendada: ${event.appointmentId}', name: 'AppointmentBloc');
    } catch (e) {
      log('Error al reagendar cita: $e', name: 'AppointmentBloc');
      emit(
        AppointmentState.error(errorMessage: 'Error al reagendar la cita: $e'),
      );
    }
  }

  Future<void> _onCompleteAppointment(
    CompleteAppointmentEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.loading());

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      // Buscar y actualizar la cita
      final appointmentIndex = _mockAppointments.indexWhere(
        (apt) => apt.id == event.appointmentId,
      );

      if (appointmentIndex == -1) {
        throw Exception('Cita no encontrada');
      }

      final updatedAppointment = _mockAppointments[appointmentIndex].copyWith(
        status: AppointmentStatus.completed,
        completedAt: DateTime.now(),
        psychologistNotes: event.notes,
      );

      _mockAppointments[appointmentIndex] = updatedAppointment;

      emit(AppointmentState.loaded(appointments: _mockAppointments));

      log('Cita completada: ${event.appointmentId}', name: 'AppointmentBloc');
    } catch (e) {
      log('Error al completar cita: $e', name: 'AppointmentBloc');
      emit(
        AppointmentState.error(errorMessage: 'Error al completar la cita: $e'),
      );
    }
  }

  Future<void> _onLoadAvailableTimeSlots(
    LoadAvailableTimeSlotsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.loading());

      // Simular delay de red
      await Future.delayed(const Duration(milliseconds: 600));

      // Generar slots de tiempo disponibles (mock)
      final slots = _generateTimeSlots(event.date, event.psychologistId);

      emit(AppointmentState.timeSlotsLoaded(timeSlots: slots));

      log('Slots de tiempo cargados: ${slots.length}', name: 'AppointmentBloc');
    } catch (e) {
      log('Error al cargar slots de tiempo: $e', name: 'AppointmentBloc');
      emit(
        AppointmentState.error(
          errorMessage: 'Error al cargar horarios disponibles: $e',
        ),
      );
    }
  }

  Future<void> _onGetAppointmentDetails(
    GetAppointmentDetailsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      // Buscar la cita específica
      final appointment = _mockAppointments.firstWhere(
        (apt) => apt.id == event.appointmentId,
      );

      emit(state.copyWith(selectedAppointment: appointment));

      log(
        'Detalles de cita cargados: ${event.appointmentId}',
        name: 'AppointmentBloc',
      );
    } catch (e) {
      log('Error al cargar detalles de cita: $e', name: 'AppointmentBloc');
      emit(AppointmentState.error(errorMessage: 'Cita no encontrada'));
    }
  }

  List<TimeSlot> _generateTimeSlots(DateTime date, String psychologistId) {
    final slots = <TimeSlot>[];

    // Verificar si es fin de semana
    if (date.weekday == 6 || date.weekday == 7) {
      return slots; // Sin slots los fines de semana
    }

    // Generar slots de 9:00 AM a 6:00 PM
    for (int hour = 9; hour < 18; hour++) {
      final slotDateTime = DateTime(date.year, date.month, date.day, hour, 0);

      // Verificar si el slot ya está ocupado
      final isOccupied = _mockAppointments.any(
        (apt) =>
            apt.psychologistId == psychologistId &&
            apt.scheduledDateTime.isAtSameMomentAs(slotDateTime) &&
            apt.status != AppointmentStatus.cancelled,
      );

      // Verificar si es en el pasado
      final isPast = slotDateTime.isBefore(DateTime.now());

      slots.add(
        TimeSlot(
          time: '${hour.toString().padLeft(2, '0')}:00',
          dateTime: slotDateTime,
          isAvailable: !isOccupied && !isPast,
          reason: isOccupied
              ? 'Ocupado'
              : isPast
              ? 'Pasado'
              : null,
        ),
      );
    }

    return slots;
  }

  // HANDLER TEMPORAL PARA CARGAR CITAS DE MUESTRA (SOLO PARA PRUEBAS)
  Future<void> _onLoadSampleAppointments(
    LoadSampleAppointmentsEvent event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      emit(AppointmentState.loading());

      // Agregar las citas de muestra a la lista
      _mockAppointments.clear();
      _mockAppointments.addAll(event.appointments);

      // Simular delay
      await Future.delayed(const Duration(milliseconds: 500));

      emit(AppointmentState.loaded(appointments: List.from(_mockAppointments)));
    } catch (e) {
      emit(
        AppointmentState.error(
          errorMessage: 'Error al cargar citas de muestra: $e',
        ),
      );
    }
  }
}
