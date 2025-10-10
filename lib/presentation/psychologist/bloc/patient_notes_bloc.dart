// lib/presentation/psychologist/bloc/patient_notes_bloc.dart

import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/services/patient_notes_service.dart';
import 'patient_notes_event.dart';
import 'patient_notes_state.dart';

class PatientNotesBloc extends Bloc<PatientNotesEvent, PatientNotesState> {
  final PatientNotesService _notesService;

  PatientNotesBloc({PatientNotesService? notesService})
      : _notesService = notesService ?? PatientNotesService(),
        super(PatientNotesState.initial()) {
    on<LoadPatientNotesEvent>(_onLoadPatientNotes);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<RefreshNotesEvent>(_onRefreshNotes);
  }

  Future<void> _onLoadPatientNotes(
    LoadPatientNotesEvent event,
    Emitter<PatientNotesState> emit,
  ) async {
    try {
      if (isClosed) return;

      emit(state.copyWith(
        status: PatientNotesStatus.loading,
        currentPatientId: event.patientId,
        clearMessages: true,
      ));

      final notes = await _notesService.getPatientNotes(event.patientId);

      if (isClosed) return;

      emit(state.copyWith(
        status: PatientNotesStatus.loaded,
        notes: notes,
        currentPatientId: event.patientId,
      ));

      log('Notas cargadas: ${notes.length}', name: 'PatientNotesBloc');
    } catch (e) {
      if (!isClosed) {
        log('Error cargando notas: $e', name: 'PatientNotesBloc');
        emit(state.copyWith(
          status: PatientNotesStatus.error,
          errorMessage: 'Error al cargar las notas: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onCreateNote(
    CreateNoteEvent event,
    Emitter<PatientNotesState> emit,
  ) async {
    try {
      if (isClosed) return;

      emit(state.copyWith(
        status: PatientNotesStatus.creating,
        clearMessages: true,
      ));

      final newNote = await _notesService.createNote(
        patientId: event.patientId,
        title: event.title,
        content: event.content,
      );

      if (isClosed) return;

      final updatedNotes = [newNote, ...state.notes];

      emit(state.copyWith(
        status: PatientNotesStatus.success,
        notes: updatedNotes,
        successMessage: 'Nota creada exitosamente',
      ));

      log('Nota creada: ${newNote.id}', name: 'PatientNotesBloc');

      // Volver a estado loaded después de 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      if (!isClosed) {
        emit(state.copyWith(
          status: PatientNotesStatus.loaded,
          clearMessages: true,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        log('Error creando nota: $e', name: 'PatientNotesBloc');
        emit(state.copyWith(
          status: PatientNotesStatus.error,
          errorMessage: 'Error al crear la nota: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onUpdateNote(
    UpdateNoteEvent event,
    Emitter<PatientNotesState> emit,
  ) async {
    try {
      if (isClosed) return;

      emit(state.copyWith(
        status: PatientNotesStatus.updating,
        clearMessages: true,
      ));

      final updatedNote = await _notesService.updateNote(
        noteId: event.noteId,
        patientId: event.patientId,
        title: event.title,
        content: event.content,
      );

      if (isClosed) return;

      final updatedNotes = state.notes.map((note) {
        return note.id == event.noteId ? updatedNote : note;
      }).toList();

      emit(state.copyWith(
        status: PatientNotesStatus.success,
        notes: updatedNotes,
        successMessage: 'Nota actualizada exitosamente',
      ));

      log('Nota actualizada: ${updatedNote.id}', name: 'PatientNotesBloc');

      // Volver a estado loaded después de 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      if (!isClosed) {
        emit(state.copyWith(
          status: PatientNotesStatus.loaded,
          clearMessages: true,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        log('Error actualizando nota: $e', name: 'PatientNotesBloc');
        emit(state.copyWith(
          status: PatientNotesStatus.error,
          errorMessage: 'Error al actualizar la nota: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onDeleteNote(
    DeleteNoteEvent event,
    Emitter<PatientNotesState> emit,
  ) async {
    try {
      if (isClosed) return;

      emit(state.copyWith(
        status: PatientNotesStatus.deleting,
        clearMessages: true,
      ));

      await _notesService.deleteNote(event.noteId);

      if (isClosed) return;

      final updatedNotes = state.notes
          .where((note) => note.id != event.noteId)
          .toList();

      emit(state.copyWith(
        status: PatientNotesStatus.success,
        notes: updatedNotes,
        successMessage: 'Nota eliminada exitosamente',
      ));

      log('Nota eliminada: ${event.noteId}', name: 'PatientNotesBloc');

      // Volver a estado loaded después de 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      if (!isClosed) {
        emit(state.copyWith(
          status: PatientNotesStatus.loaded,
          clearMessages: true,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        log('Error eliminando nota: $e', name: 'PatientNotesBloc');
        emit(state.copyWith(
          status: PatientNotesStatus.error,
          errorMessage: 'Error al eliminar la nota: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onRefreshNotes(
    RefreshNotesEvent event,
    Emitter<PatientNotesState> emit,
  ) async {
    try {
      if (isClosed) return;

      final notes = await _notesService.getPatientNotes(event.patientId);

      if (isClosed) return;

      emit(state.copyWith(
        status: PatientNotesStatus.loaded,
        notes: notes,
      ));

      log('Notas actualizadas: ${notes.length}', name: 'PatientNotesBloc');
    } catch (e) {
      if (!isClosed) {
        log('Error actualizando notas: $e', name: 'PatientNotesBloc');
      }
    }
  }
}