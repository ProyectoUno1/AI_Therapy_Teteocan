// lib/presentation/psychologist/bloc/patient_management_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';

enum PatientManagementStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

class PatientManagementState extends Equatable {
  final PatientManagementStatus status;
  final List<PatientManagementModel> allPatients;
  final List<PatientManagementModel> filteredPatients;
  final String searchQuery;
  final PatientStatus? selectedFilter;
  final String? errorMessage;
  final bool isSearching;
  final String? psychologistId; 
  
  final List<PatientManagementModel> pendingPatients;
  final List<PatientManagementModel> inTreatmentPatients;
  final List<PatientManagementModel> completedPatients;

  const PatientManagementState({
    this.status = PatientManagementStatus.initial,
    this.allPatients = const [],
    this.filteredPatients = const [],
    this.searchQuery = '',
    this.selectedFilter,
    this.errorMessage,
    this.isSearching = false,
    this.psychologistId,
    this.pendingPatients = const [],
    this.inTreatmentPatients = const [],
    this.completedPatients = const [],
  });

  @override
  List<Object?> get props => [
        status,
        allPatients,
        filteredPatients,
        searchQuery,
        selectedFilter,
        errorMessage,
        isSearching,
        psychologistId,
        pendingPatients,
        inTreatmentPatients,
        completedPatients,
      ];

  PatientManagementState copyWith({
    PatientManagementStatus? status,
    List<PatientManagementModel>? allPatients,
    List<PatientManagementModel>? filteredPatients,
    String? searchQuery,
    PatientStatus? selectedFilter,
    String? errorMessage,
    bool? isSearching,
    String? psychologistId,
    List<PatientManagementModel>? pendingPatients,
    List<PatientManagementModel>? inTreatmentPatients,
    List<PatientManagementModel>? completedPatients,
    bool clearFilter = false,
  }) {
    return PatientManagementState(
      status: status ?? this.status,
      allPatients: allPatients ?? this.allPatients,
      filteredPatients: filteredPatients ?? this.filteredPatients,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: clearFilter ? null : (selectedFilter ?? this.selectedFilter),
      errorMessage: errorMessage,
      isSearching: isSearching ?? this.isSearching,
      psychologistId: psychologistId ?? this.psychologistId,
      pendingPatients: pendingPatients ?? this.pendingPatients,
      inTreatmentPatients: inTreatmentPatients ?? this.inTreatmentPatients,
      completedPatients: completedPatients ?? this.completedPatients,
    );
  }

  static PatientManagementState initial() {
    return const PatientManagementState();
  }
}