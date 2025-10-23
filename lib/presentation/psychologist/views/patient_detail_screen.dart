// lib/presentation/psychologist/views/patient_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/schedule_appointment_form.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_notes_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/add_edit_note_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_notes_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_progress_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientManagementModel patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PatientManagementModel _patient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _patient = widget.patient;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalles del Paciente',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          if (_patient.status != PatientStatus.completed)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Marcar como completado',
              onPressed: () => _showCompletePatientDialog(),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Tratamiento completado',
              onPressed: null,
            ),
        ],
      ),
      body: Column(
        children: [
          // Header con información básica
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Avatar y nombre
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      backgroundImage: _patient.profilePictureUrl != null
                          ? NetworkImage(_patient.profilePictureUrl!)
                          : null,
                      child: _patient.profilePictureUrl == null
                          ? Text(
                              _patient.name.isNotEmpty
                                  ? _patient.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _patient.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(_patient.contactMethod.icon),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _patient.contactMethod.displayName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                _patient.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_patient.status.icon),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _patient.status.displayName,
                                    style: TextStyle(
                                      color: _getStatusColor(_patient.status),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildClickableStatCard(
                        icon: Icons.calendar_today,
                        title: 'Sesiones',
                        value: '${_patient.totalSessions}',
                        color: AppConstants.primaryColor,
                        onTap: () => _onSessionsCardTap(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClickableStatCard(
                        icon: Icons.schedule,
                        title: 'Días activo',
                        value:
                            '${DateTime.now().difference(_patient.createdAt).inDays}',
                        color: Colors.green,
                        onTap: () => _onActiveDaysCardTap(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClickableStatCard(
                        icon: Icons.trending_up,
                        title: 'Progreso',
                        value: _getProgressPercentage(),
                        color: Colors.orange,
                        onTap: () => _onProgressCardTap(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppConstants.primaryColor,
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Información'),
                Tab(icon: Icon(Icons.history), text: 'Historial'),
                Tab(icon: Icon(Icons.note), text: 'Notas'),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInformationTab(),
                _buildHistoryTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scheduleAppointment(),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.event_available, color: Colors.white),
        label: const Text(
          'Agendar Cita',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildClickableStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Icon(Icons.touch_app, size: 14, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  void _onSessionsCardTap() {
    _tabController.animateTo(1);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.calendar_today, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resumen de Sesiones',
                  style: TextStyle(fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow(
                'Total de sesiones:',
                '${_patient.totalSessions}',
              ),
              _buildDialogInfoRow(
                'Sesiones completadas:',
                '${_patient.totalSessions}',
              ),
              _buildDialogInfoRow(
                'Próxima sesión:',
                _patient.nextAppointment != null
                    ? _formatDateTime(_patient.nextAppointment!)
                    : 'No programada',
              ),
              _buildDialogInfoRow(
                'Última sesión:',
                _patient.lastAppointment != null
                    ? _formatDateTime(_patient.lastAppointment!)
                    : 'No hay registro',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TextStyle(color: AppConstants.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _scheduleAppointment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
              child: const Text(
                'Agendar Nueva',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onActiveDaysCardTap() {
    final activeDays = DateTime.now().difference(_patient.createdAt).inDays;
    final weeks = (activeDays / 7).floor();
    final months = (activeDays / 30).floor();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tiempo Activo',
                  style: TextStyle(fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow('Días activo:', '$activeDays días'),
              _buildDialogInfoRow('Equivale a:', '$weeks semanas'),
              _buildDialogInfoRow('Aproximadamente:', '$months meses'),
              _buildDialogInfoRow(
                'Fecha de registro:',
                _formatDateTime(_patient.createdAt),
              ),
              _buildDialogInfoRow(
                'Última actualización:',
                _formatDateTime(_patient.updatedAt),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _onProgressCardTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProgressScreen(
          patientId: _patient.id!,
          patientName: _patient.name,
          totalSessions: _patient.totalSessions,
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressDescription(int progress) {
    if (progress == 0) {
      return 'El tratamiento está en fase inicial. Se recomienda establecer objetivos claros.';
    } else if (progress < 30) {
      return 'El paciente está comenzando su proceso terapéutico. Mantener seguimiento cercano.';
    } else if (progress < 60) {
      return 'El tratamiento muestra avance moderado. Continuar con el plan establecido.';
    } else if (progress < 90) {
      return 'Excelente progreso en el tratamiento. El paciente muestra mejoras significativas.';
    } else if (progress < 100) {
      return 'El tratamiento está cerca de completarse. Preparar plan de seguimiento.';
    } else {
      return 'El paciente ha completado su tratamiento exitosamente. Considerar sesiones de mantenimiento.';
    }
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: 'Información Personal',
            icon: Icons.person,
            children: [
              _buildInfoRow('Nombre completo', _patient.name),
              _buildInfoRow('Correo electrónico', _patient.email),
              if (_patient.phoneNumber != null)
                _buildInfoRow('Teléfono', _patient.phoneNumber!),
              if (_patient.dateOfBirth != null)
                _buildInfoRow(
                  'Fecha de nacimiento',
                  '${_patient.dateOfBirth!.day}/${_patient.dateOfBirth!.month}/${_patient.dateOfBirth!.year}',
                ),
              if (_patient.dateOfBirth != null)
                _buildInfoRow(
                  'Edad',
                  '${_calculateAge(_patient.dateOfBirth!)} años',
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            title: 'Estado del Tratamiento',
            icon: Icons.medical_services,
            children: [
              _buildInfoRow('Estado actual', _patient.status.displayName),
              _buildInfoRow(
                'Método de contacto',
                _patient.contactMethod.displayName,
              ),
              _buildInfoRow(
                'Fecha de registro',
                _formatDateTime(_patient.createdAt),
              ),
              _buildInfoRow(
                'Última actualización',
                _formatDateTime(_patient.updatedAt),
              ),
              if (_patient.lastAppointment != null)
                _buildInfoRow(
                  'Última cita',
                  _formatDateTime(_patient.lastAppointment!),
                ),
              if (_patient.nextAppointment != null)
                _buildInfoRow(
                  'Próxima cita',
                  _formatDateTime(_patient.nextAppointment!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Sesiones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),

          for (int i = 0; i < _patient.totalSessions; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sesión ${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          _formatDateTime(
                            DateTime.now().subtract(
                              Duration(days: (i + 1) * 7),
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),

          if (_patient.totalSessions == 0)
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Sin sesiones registradas',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Notas del Paciente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                onPressed: () => _addNote(),
                icon: Icon(Icons.add, color: AppConstants.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_patient.notes != null && _patient.notes!.isNotEmpty)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note, color: AppConstants.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notas iniciales',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppConstants.primaryColor,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _patient.notes!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewAllNotes(),
                    icon: const Icon(
                      Icons.format_list_bulleted,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Ver Historial de Notas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Column(
                children: [
                  Icon(Icons.note_add, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Sin notas registradas',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addNote(),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Primera Nota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PatientStatus status) {
    switch (status) {
      case PatientStatus.pending:
        return Colors.orange;
      case PatientStatus.accepted:
        return Colors.blue;
      case PatientStatus.inTreatment:
        return Colors.green;
      case PatientStatus.completed:
        return AppConstants.primaryColor;
      case PatientStatus.cancelled:
        return Colors.red;
    }
  }

  String _getProgressPercentage() {
    if (_patient.totalSessions == 0) return '0%';
    final progress = (_patient.totalSessions / 10 * 100).clamp(0, 100);
    return '${progress.toInt()}%';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _scheduleAppointment() {
    final psychologistId = context.read<AuthBloc>().state.psychologist?.uid;
    final patient = widget.patient;

    if (psychologistId == null || patient.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener el ID del usuario.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleAppointmentForm(
          psychologistId: psychologistId,
          patient: patient,
        ),
      ),
    );
  }

  void _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<PatientNotesBloc>(),
          child: AddEditNoteScreen(patientId: _patient.id!),
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nota guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewAllNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<PatientNotesBloc>(),
          child: PatientNotesScreen(
            patientId: _patient.id!,
            patientName: _patient.name,
          ),
        ),
      ),
    );
  }

  // NUEVOS MÉTODOS PARA COMPLETAR PACIENTE
  void _showCompletePatientDialog() {
    final TextEditingController notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Completar Tratamiento',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Estás seguro de marcar el tratamiento de ${_patient.name} como completado?',
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Información',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total de sesiones: ${_patient.totalSessions}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                        ),
                      ),
                      if (_patient.lastAppointment != null)
                        Text(
                          'Última sesión: ${_formatDateTime(_patient.lastAppointment!)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notas finales (opcional):',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Agrega observaciones sobre el cierre del tratamiento...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _completePatient(notesController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completePatient(String finalNotes) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final response = await http.patch(
        Uri.parse(
          '${AppConstants.baseUrl}/patient-management/patients/${_patient.id}/complete',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode({'finalNotes': finalNotes}),
      );

      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        setState(() {
          _patient = _patient.copyWith(
            status: PatientStatus.completed,
            updatedAt: DateTime.now(),
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente marcado como completado'),
              backgroundColor: Colors.green,
            ),
          );
          _showCompletionSuccessDialog();
        }
      } else {
        throw Exception('Error al completar paciente');
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

 void _showCompletionSuccessDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Tratamiento Completado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'El tratamiento de ${_patient.name} ha sido marcado como completado.',
              style: const TextStyle(fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); 
              Navigator.of(context).pop(true); 
            },
            child: Text(
              'Entendido',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
      );
    },
  );
}
}
