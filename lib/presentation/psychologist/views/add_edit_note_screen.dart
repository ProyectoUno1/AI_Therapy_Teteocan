// lib/presentation/psychologist/views/add_edit_note_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
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
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final buttonHeight = ResponsiveUtils.getButtonHeight(context);
    final isMobileSmall = ResponsiveUtils.isMobileSmall(context);
    
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
          title: ResponsiveText(
            _isEditing ? 'Editar Nota' : 'Nueva Nota',
            baseFontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: ResponsiveUtils.getIconSize(context, 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<PatientNotesBloc, PatientNotesState>(
          builder: (context, state) {
            final isLoading = state.status == PatientNotesStatus.creating ||
                state.status == PatientNotesStatus.updating;

            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                        ),
                        hintText: 'Ej: Primera Sesión, Seguimiento...',
                        hintStyle: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, 12),
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.title,
                          size: ResponsiveUtils.getIconSize(context, 24),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: ResponsiveUtils.getVerticalPadding(context),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 16),
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
                    ResponsiveSpacing(16),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Contenido',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                        ),
                        hintText: 'Escribe tus observaciones aquí...',
                        hintStyle: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, 12),
                          ),
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Icon(
                            Icons.note,
                            size: ResponsiveUtils.getIconSize(context, 24),
                          ),
                        ),
                        alignLabelWithHint: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: ResponsiveUtils.getVerticalPadding(context) * 1.5,
                        ),
                      ),
                      maxLines: isMobileSmall ? 12 : 15,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 16),
                      ),
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
                    ResponsiveSpacing(24),
                    SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getBorderRadius(context, 12),
                            ),
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
                            : ResponsiveText(
                                _isEditing ? 'Guardar Cambios' : 'Crear Nota',
                                baseFontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    if (isLoading) ...[
                      ResponsiveSpacing(16),
                      Center(
                        child: ResponsiveText(
                          'Guardando nota...',
                          baseFontSize: 14,
                          color: Colors.grey,
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