// lib/presentation/psychologist/views/patient_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/schedule_appointment_form.dart';

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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editPatient(),
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
                // Avatar y nombre - CORREGIDO CON EXPANDED
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
                    Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
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
                            overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                            maxLines: 2, // SOLUCIÓN OVERFLOW
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(_patient.contactMethod.icon),
                              const SizedBox(width: 8),
                              Flexible( // SOLUCIÓN OVERFLOW - AGREGADO FLEXIBLE
                                child: Text(
                                  _patient.contactMethod.displayName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                  overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                                  maxLines: 1, // SOLUCIÓN OVERFLOW
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
                                Flexible( // SOLUCIÓN OVERFLOW - AGREGADO FLEXIBLE
                                  child: Text(
                                    _patient.status.displayName,
                                    style: TextStyle(
                                      color: _getStatusColor(_patient.status),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                                    maxLines: 1, // SOLUCIÓN OVERFLOW
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

                // Estadísticas rápidas - CLICKEABLES Y CORREGIDAS
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
                        value: '${DateTime.now().difference(_patient.createdAt).inDays}',
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

  // FUNCIÓN: Widget clickeable para las estadísticas - CORREGIDO
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
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
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
              textAlign: TextAlign.center, // SOLUCIÓN OVERFLOW
              overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
              maxLines: 1, // SOLUCIÓN OVERFLOW
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center, // SOLUCIÓN OVERFLOW
              overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
              maxLines: 1, // SOLUCIÓN OVERFLOW
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.touch_app,
              size: 14,
              color: color.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  // FUNCIONES: Manejadores de eventos para cada tarjeta
  void _onSessionsCardTap() {
    // Cambiar a la pestaña de historial automáticamente
    _tabController.animateTo(1);
    
    // Mostrar información adicional sobre las sesiones
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
              Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
                child: Text(
                  'Resumen de Sesiones',
                  style: TextStyle(fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow('Total de sesiones:', '${_patient.totalSessions}'),
              _buildDialogInfoRow('Sesiones completadas:', '${_patient.totalSessions}'),
              _buildDialogInfoRow('Próxima sesión:', 
                _patient.nextAppointment != null 
                  ? _formatDateTime(_patient.nextAppointment!)
                  : 'No programada'
              ),
              _buildDialogInfoRow('Última sesión:', 
                _patient.lastAppointment != null 
                  ? _formatDateTime(_patient.lastAppointment!)
                  : 'No hay registro'
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
              Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
                child: Text(
                  'Tiempo Activo',
                  style: TextStyle(fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
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
              _buildDialogInfoRow('Fecha de registro:', _formatDateTime(_patient.createdAt)),
              _buildDialogInfoRow('Última actualización:', _formatDateTime(_patient.updatedAt)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onProgressCardTap() {
    final progressPercentage = _getProgressPercentage();
    final progressValue = int.parse(progressPercentage.replaceAll('%', ''));
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.trending_up, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
                child: Text(
                  'Progreso del Tratamiento',
                  style: TextStyle(fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                ),
              ),
            ],
          ),
          content: SingleChildScrollView( // SOLUCIÓN OVERFLOW - AGREGADO SCROLLVIEW
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de progreso visual
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity * (progressValue / 100),
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Center(
                        child: Text(
                          progressPercentage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDialogInfoRow('Progreso actual:', progressPercentage),
                _buildDialogInfoRow('Sesiones completadas:', '${_patient.totalSessions}'),
                _buildDialogInfoRow('Meta estimada:', '10 sesiones'),
                _buildDialogInfoRow('Estado:', _patient.status.displayName),
                const SizedBox(height: 8),
                Text(
                  _getProgressDescription(progressValue),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            if (progressValue < 100)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _tabController.animateTo(2); // IR a la pestaña de notas
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text(
                  'Agregar Nota',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  // FUNCIÓN AUXILIAR: Para mostrar información en los diálogos - CORREGIDA
  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // REDUCIDO PARA EVITAR OVERFLOW
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
          Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
              maxLines: 2, // SOLUCIÓN OVERFLOW
            ),
          ),
        ],
      ),
    );
  }

  // FUNCIÓN AUXILIAR: Descripción del progreso
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

          // Lista de sesiones simulada - CORREGIDA
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
                  Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sesión ${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                          maxLines: 1, // SOLUCIÓN OVERFLOW
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
                          overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                          maxLines: 1, // SOLUCIÓN OVERFLOW
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
                    textAlign: TextAlign.center, // SOLUCIÓN OVERFLOW
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
              Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
                child: Text(
                  'Notas del Paciente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                  overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                  maxLines: 1, // SOLUCIÓN OVERFLOW
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
                      Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
                        child: Text(
                          'Notas iniciales',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                          maxLines: 1, // SOLUCIÓN OVERFLOW
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _patient.notes!,
                    style: const TextStyle(fontFamily: 'Poppins', height: 1.5),
                  ),
                ],
              ),
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
                    textAlign: TextAlign.center, // SOLUCIÓN OVERFLOW
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
              Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                  maxLines: 1, // SOLUCIÓN OVERFLOW
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
          Expanded( // SOLUCIÓN OVERFLOW - AGREGADO EXPANDED
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
              maxLines: 2, // SOLUCIÓN OVERFLOW
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
    // Lógica simple para calcular progreso basado en sesiones
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

  void _editPatient() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de editar paciente próximamente')),
    );
  }

  void _scheduleAppointment() {
    final psychologistId = context.read<AuthBloc>().state.psychologist?.uid;
    final patient = widget.patient;
    
    if (psychologistId == null || patient.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: No se pudo obtener el ID del usuario.')),
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

  void _addNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de agregar nota próximamente')),
    );
  }
}