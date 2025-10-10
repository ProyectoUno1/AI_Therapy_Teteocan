// lib/presentation/psychologist/bloc/patient_notes_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_note.dart';

enum PatientNotesStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  success,
  error,
}

class PatientNotesState extends Equatable {
  final PatientNotesStatus status;
  final List<PatientNote> notes;
  final String? errorMessage;
  final String? successMessage;
  final String? currentPatientId;

  const PatientNotesState({
    this.status = PatientNotesStatus.initial,
    this.notes = const [],
    this.errorMessage,
    this.successMessage,
    this.currentPatientId,
  });

  @override
  List<Object?> get props => [
        status,
        notes,
        errorMessage,
        successMessage,
        currentPatientId,
      ];

  PatientNotesState copyWith({
    PatientNotesStatus? status,
    List<PatientNote>? notes,
    String? errorMessage,
    String? successMessage,
    String? currentPatientId,
    bool clearMessages = false,
  }) {
    return PatientNotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      errorMessage: clearMessages ? null : errorMessage,
      successMessage: clearMessages ? null : successMessage,
      currentPatientId: currentPatientId ?? this.currentPatientId,
    );
  }

  static PatientNotesState initial() {
    return const PatientNotesState();
  }
}