// lib/presentation/psychologist/bloc/patient_management_event.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

abstract class PatientManagementEvent extends Equatable {
  const PatientManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadPatientsEvent extends PatientManagementEvent {
  final String psychologistId;
  const LoadPatientsEvent({required this.psychologistId});

  @override
  List<Object?> get props => [psychologistId];
}

class SearchPatientsEvent extends PatientManagementEvent {
  final String query;
  const SearchPatientsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class FilterPatientsByStatusEvent extends PatientManagementEvent {
  final PatientStatus? status;
  const FilterPatientsByStatusEvent({this.status});

  @override
  List<Object?> get props => [status];
}

class RefreshPatientsEvent extends PatientManagementEvent {}

class AddPatientToListEvent extends PatientManagementEvent {
  final PatientManagementModel patient;
  const AddPatientToListEvent({required this.patient});
  @override
  List<Object?> get props => [patient];
}

class UpdatePatientInListEvent extends PatientManagementEvent {
  final PatientManagementModel patient;
  const UpdatePatientInListEvent({required this.patient});
  @override
  List<Object?> get props => [patient];
}

class RemovePatientFromListEvent extends PatientManagementEvent {
  final String patientId;
  const RemovePatientFromListEvent({required this.patientId});
  @override
  List<Object?> get props => [patientId];
}