import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/services/patient_management_service.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';
import 'patient_management_event.dart';
import 'patient_management_state.dart';

class PatientManagementBloc extends Bloc<PatientManagementEvent, PatientManagementState> {
  final PatientManagementService _patientService;
  Timer? _refreshTimer;

  PatientManagementBloc({PatientManagementService? patientService})
      : _patientService = patientService ?? PatientManagementService(),
        super(PatientManagementState.initial()) {
    
    on<LoadPatientsEvent>(_onLoadPatients);
    on<SearchPatientsEvent>(_onSearchPatients);
    on<FilterPatientsByStatusEvent>(_onFilterPatientsByStatus);
    on<RefreshPatientsEvent>(_onRefreshPatients);
    on<AddPatientToListEvent>(_onAddPatientToList);
    on<UpdatePatientInListEvent>(_onUpdatePatientInList);
    on<RemovePatientFromListEvent>(_onRemovePatientFromList);

    // Configurar actualización automática cada 30 segundos
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isClosed && state.status != PatientManagementStatus.loading && state.psychologistId != null) {
        add(RefreshPatientsEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadPatients(
    LoadPatientsEvent event,
    Emitter<PatientManagementState> emit,
  ) async {
    try {
      if (isClosed) return;
      
      // Guardar el psychologistId en el estado para futuros usos
      emit(state.copyWith(status: PatientManagementStatus.loading, psychologistId: state.psychologistId));

      // Pasar la ID del psicólogo al servicio para cargar los pacientes
      final patients = await _patientService.getPatientsForPsychologist(psychologistId: event.psychologistId);

      if (isClosed) return;

      // Aplicar filtros existentes y actualizar todas las listas
      final filteredPatients = _applyFilters(patients, state.searchQuery, state.selectedFilter);

      emit(state.copyWith(
        status: PatientManagementStatus.loaded,
        allPatients: patients,
        filteredPatients: filteredPatients,
        pendingPatients: _filterByStatus(patients, PatientStatus.pending),
        inTreatmentPatients: _filterByStatus(patients, PatientStatus.inTreatment),
        completedPatients: _filterByStatus(patients, PatientStatus.completed),
        psychologistId: event.psychologistId,
      ));

    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: PatientManagementStatus.error,
          errorMessage: 'Error al cargar pacientes: ${e.toString()}',
          psychologistId: state.psychologistId,
        ));
      }
    }
  }

  Future<void> _onSearchPatients(
    SearchPatientsEvent event,
    Emitter<PatientManagementState> emit,
  ) async {
    if (isClosed) return;

    emit(state.copyWith(isSearching: true, psychologistId: state.psychologistId));

    // Pequeño delay para evitar búsquedas demasiado frecuentes
    await Future.delayed(const Duration(milliseconds: 300));

    if (!isClosed) {
      final filteredPatients = _applyFilters(
        state.allPatients, 
        event.query, 
        state.selectedFilter
      );

      emit(state.copyWith(
        searchQuery: event.query,
        filteredPatients: filteredPatients,
        isSearching: false,
        pendingPatients: _filterByStatus(state.allPatients, PatientStatus.pending),
        inTreatmentPatients: _filterByStatus(state.allPatients, PatientStatus.inTreatment),
        completedPatients: _filterByStatus(state.allPatients, PatientStatus.completed),
        psychologistId: state.psychologistId,
      ));
    }
  }

  void _onFilterPatientsByStatus(
    FilterPatientsByStatusEvent event,
    Emitter<PatientManagementState> emit,
  ) {
    if (isClosed) return;

    final filteredPatients = _applyFilters(
      state.allPatients, 
      state.searchQuery, 
      event.status
    );

    emit(state.copyWith(
      selectedFilter: event.status,
      filteredPatients: filteredPatients,
      clearFilter: event.status == null,
      pendingPatients: _filterByStatus(state.allPatients, PatientStatus.pending),
      inTreatmentPatients: _filterByStatus(state.allPatients, PatientStatus.inTreatment),
      completedPatients: _filterByStatus(state.allPatients, PatientStatus.completed),
      psychologistId: state.psychologistId,
    ));
  }

  Future<void> _onRefreshPatients(
    RefreshPatientsEvent event,
    Emitter<PatientManagementState> emit,
  ) async {
    try {
      if (isClosed) return;
      
      emit(state.copyWith(status: PatientManagementStatus.refreshing, psychologistId: state.psychologistId));
      
      // Pasar la ID del psicólogo al servicio para actualizar los pacientes
      final patients = await _patientService.getPatientsForPsychologist(psychologistId: state.psychologistId!);

      if (isClosed) return;

      final filteredPatients = _applyFilters(patients, state.searchQuery, state.selectedFilter);

      emit(state.copyWith(
        status: PatientManagementStatus.loaded,
        allPatients: patients,
        filteredPatients: filteredPatients,
        pendingPatients: _filterByStatus(patients, PatientStatus.pending),
        inTreatmentPatients: _filterByStatus(patients, PatientStatus.inTreatment),
        completedPatients: _filterByStatus(patients, PatientStatus.completed),
        psychologistId: state.psychologistId,
      ));

    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: PatientManagementStatus.loaded,
          psychologistId: state.psychologistId,
        ));
      }
    }
  }

  void _onAddPatientToList(
    AddPatientToListEvent event,
    Emitter<PatientManagementState> emit,
  ) {
    if (isClosed) return;

    final updatedAllPatients = List<PatientManagementModel>.from(state.allPatients)
      ..add(event.patient);

    final filteredPatients = _applyFilters(
      updatedAllPatients, 
      state.searchQuery, 
      state.selectedFilter
    );

    emit(state.copyWith(
      allPatients: updatedAllPatients,
      filteredPatients: filteredPatients,
      pendingPatients: _filterByStatus(updatedAllPatients, PatientStatus.pending),
      inTreatmentPatients: _filterByStatus(updatedAllPatients, PatientStatus.inTreatment),
      completedPatients: _filterByStatus(updatedAllPatients, PatientStatus.completed),
      psychologistId: state.psychologistId,
    ));
  }

  void _onUpdatePatientInList(
    UpdatePatientInListEvent event,
    Emitter<PatientManagementState> emit,
  ) {
    if (isClosed) return;

    final updatedAllPatients = state.allPatients.map((p) {
      return p.id == event.patient.id ? event.patient : p;
    }).toList();

    final filteredPatients = _applyFilters(
      updatedAllPatients, 
      state.searchQuery, 
      state.selectedFilter
    );

    emit(state.copyWith(
      allPatients: updatedAllPatients,
      filteredPatients: filteredPatients,
      status: PatientManagementStatus.loaded,
      pendingPatients: _filterByStatus(updatedAllPatients, PatientStatus.pending),
      inTreatmentPatients: _filterByStatus(updatedAllPatients, PatientStatus.inTreatment),
      completedPatients: _filterByStatus(updatedAllPatients, PatientStatus.completed),
      psychologistId: state.psychologistId,
    ));
  }

  void _onRemovePatientFromList(
    RemovePatientFromListEvent event,
    Emitter<PatientManagementState> emit,
  ) {
    if (isClosed) return;

    final updatedAllPatients = state.allPatients
        .where((patient) => patient.id != event.patientId)
        .toList();

    final filteredPatients = _applyFilters(
      updatedAllPatients, 
      state.searchQuery, 
      state.selectedFilter
    );

    emit(state.copyWith(
      allPatients: updatedAllPatients,
      filteredPatients: filteredPatients,
      pendingPatients: _filterByStatus(updatedAllPatients, PatientStatus.pending),
      inTreatmentPatients: _filterByStatus(updatedAllPatients, PatientStatus.inTreatment),
      completedPatients: _filterByStatus(updatedAllPatients, PatientStatus.completed),
      psychologistId: state.psychologistId,
    ));
  }

  // Función helper para aplicar filtros
  List<PatientManagementModel> _applyFilters(
    List<PatientManagementModel> patients,
    String searchQuery,
    PatientStatus? statusFilter,
  ) {
    var filtered = List<PatientManagementModel>.from(patients);

    // Aplicar filtro de búsqueda
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
               patient.email.toLowerCase().contains(query) ||
               (patient.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Aplicar filtro de status
    if (statusFilter != null) {
      filtered = filtered.where((patient) => patient.status == statusFilter).toList();
    }

    return filtered;
  }

  List<PatientManagementModel> _filterByStatus(List<PatientManagementModel> patients, PatientStatus status) {
    return patients.where((p) => p.status == status).toList();
  }
}