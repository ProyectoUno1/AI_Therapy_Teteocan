// lib/presentation/psychologist/bloc/patient_notes_event.dart

import 'package:equatable/equatable.dart';

abstract class PatientNotesEvent extends Equatable {
  const PatientNotesEvent();

  @override
  List<Object?> get props => [];
}

// Cargar todas las notas de un paciente
class LoadPatientNotesEvent extends PatientNotesEvent {
  final String patientId;

  const LoadPatientNotesEvent({required this.patientId});

  @override
  List<Object?> get props => [patientId];
}

// Crear una nueva nota
class CreateNoteEvent extends PatientNotesEvent {
  final String patientId;
  final String title;
  final String content;

  const CreateNoteEvent({
    required this.patientId,
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [patientId, title, content];
}

// Actualizar una nota existente
class UpdateNoteEvent extends PatientNotesEvent {
  final String noteId;
  final String patientId;
  final String title;
  final String content;

  const UpdateNoteEvent({
    required this.noteId,
    required this.patientId,
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [noteId, patientId, title, content];
}

// Eliminar una nota
class DeleteNoteEvent extends PatientNotesEvent {
  final String noteId;

  const DeleteNoteEvent({required this.noteId});

  @override
  List<Object?> get props => [noteId];
}

// Refrescar las notas
class RefreshNotesEvent extends PatientNotesEvent {
  final String patientId;

  const RefreshNotesEvent({required this.patientId});

  @override
  List<Object?> get props => [patientId];
}