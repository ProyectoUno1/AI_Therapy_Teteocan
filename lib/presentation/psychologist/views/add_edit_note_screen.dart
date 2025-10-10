// lib/presentation/psychologist/views/add_edit_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/patient_note.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_notes_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_notes_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_notes_state.dart';

class AddEditNoteScreen extends StatefulWidget {
  final String patientId;
  final PatientNote? note;

  const AddEditNoteScreen({
    super.key,
    required this.patientId,
    this.note,
  });

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.note != null;

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      if (_isEditing) {
        context.read<PatientNotesBloc>().add(
              UpdateNoteEvent(
                noteId: widget.note!.id,
                patientId: widget.patientId,
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
              ),
            );
      } else {
        context.read<PatientNotesBloc>().add(
              CreateNoteEvent(
                patientId: widget.patientId,
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientNotesBloc, PatientNotesState>(
      listener: (context, state) {
        if (state.status == PatientNotesStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage ?? 'Operación exitosa'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (state.status == PatientNotesStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Error al guardar la nota'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Nota' : 'Nueva Nota'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<PatientNotesBloc, PatientNotesState>(
          builder: (context, state) {
            final isLoading = state.status == PatientNotesStatus.creating ||
                state.status == PatientNotesStatus.updating;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej: Primera Sesión, Seguimiento...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El título es requerido';
                        }
                        if (value.trim().length < 3) {
                          return 'El título debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Contenido',
                        hintText: 'Escribe tus observaciones aquí...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 15,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El contenido es requerido';
                        }
                        if (value.trim().length < 10) {
                          return 'El contenido debe tener al menos 10 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isEditing ? 'Guardar Cambios' : 'Crear Nota',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Guardando nota...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}