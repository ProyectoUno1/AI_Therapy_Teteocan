// lib/presentation/psychologist/views/patient_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
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
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtils.getVerticalPadding(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isMobileSmall = ResponsiveUtils.isMobileSmall(context);
    final avatarRadius = ResponsiveUtils.getAvatarRadius(context, 40);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: ResponsiveUtils.getIconSize(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ResponsiveText(
          'Detalles del Paciente',
          baseFontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        centerTitle: true,
        actions: [
          if (_patient.status != PatientStatus.completed)
            IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
              tooltip: 'Marcar como completado',
              onPressed: () => _showCompletePatientDialog(),
            )
          else
            IconButton(
              icon: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
              tooltip: 'Tratamiento completado',
              onPressed: null,
            ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Header con información básica
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(horizontalPadding),
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    // Avatar y nombre
                    Row(
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          backgroundImage: _patient.profilePictureUrl != null
                              ? NetworkImage(_patient.profilePictureUrl!)
                              : null,
                          child: _patient.profilePictureUrl == null
                              ? ResponsiveText(
                                  _patient.name.isNotEmpty
                                      ? _patient.name[0].toUpperCase()
                                      : '?',
                                  baseFontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        ResponsiveHorizontalSpacing(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ResponsiveText(
                                _patient.name,
                                baseFontSize: 24,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              ResponsiveSpacing(4),
                              Row(
                                children: [
                                  Text(_patient.contactMethod.icon),
                                  ResponsiveHorizontalSpacing(8),
                                  Flexible(
                                    child: ResponsiveText(
                                      _patient.contactMethod.displayName,
                                      baseFontSize: 14,
                                      color: Colors.grey[600],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveSpacing(8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.getHorizontalSpacing(context, 12),
                                  vertical: ResponsiveUtils.getVerticalSpacing(context, 6),
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    _patient.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.getBorderRadius(context, 20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_patient.status.icon),
                                    ResponsiveHorizontalSpacing(8),
                                    Flexible(
                                      child: ResponsiveText(
                                        _patient.status.displayName,
                                        baseFontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(_patient.status),
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
                    ResponsiveSpacing(16),

                    // Stats cards responsivas
                    isMobileSmall
                        ? Column(
                            children: [
                              _buildClickableStatCard(
                                icon: Icons.calendar_today,
                                title: 'Sesiones',
                                value: '${_patient.totalSessions}',
                                color: AppConstants.primaryColor,
                                onTap: () => _onSessionsCardTap(),
                              ),
                              ResponsiveSpacing(12),
                              _buildClickableStatCard(
                                icon: Icons.schedule,
                                title: 'Días activo',
                                value:
                                    '${DateTime.now().difference(_patient.createdAt).inDays}',
                                color: Colors.green,
                                onTap: () => _onActiveDaysCardTap(),
                              ),
                              ResponsiveSpacing(12),
                              _buildClickableStatCard(
                                icon: Icons.trending_up,
                                title: 'Progreso',
                                value: _getProgressPercentage(),
                                color: Colors.orange,
                                onTap: () => _onProgressCardTap(),
                              ),
                            ],
                          )
                        : Row(
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
                              ResponsiveHorizontalSpacing(12),
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
                              ResponsiveHorizontalSpacing(12),
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
            ),

            // TabBar
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).cardColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppConstants.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppConstants.primaryColor,
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                  ),
                  tabs: [
                    Tab(
                      icon: Icon(
                        Icons.info,
                        size: ResponsiveUtils.getIconSize(context, 20),
                      ),
                      text: 'Información',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.history,
                        size: ResponsiveUtils.getIconSize(context, 20),
                      ),
                      text: 'Historial',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.note,
                        size: ResponsiveUtils.getIconSize(context, 20),
                      ),
                      text: 'Notas',
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInformationTab(),
            _buildHistoryTab(),
            _buildNotesTab(),
          ],
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
        padding: EdgeInsets.all(ResponsiveUtils.getHorizontalSpacing(context, 12)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, 12),
          ),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveUtils.getIconSize(context, 24),
            ),
            ResponsiveSpacing(8),
            ResponsiveText(
              value,
              baseFontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            ResponsiveText(
              title,
              baseFontSize: 12,
              color: Colors.grey[600],
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            ResponsiveSpacing(4),
            Icon(
              Icons.touch_app,
              size: ResponsiveUtils.getIconSize(context, 14),
              color: color.withOpacity(0.7),
            ),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppConstants.primaryColor,
                      size: ResponsiveUtils.getIconSize(context, 24),
                    ),
                    ResponsiveHorizontalSpacing(8),
                    Expanded(
                      child: ResponsiveText(
                        'Resumen de Sesiones',
                        baseFontSize: 18,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                ResponsiveSpacing(16),
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
                ResponsiveSpacing(16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: ResponsiveText(
                          'Cerrar',
                          baseFontSize: 14,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _scheduleAppointment();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: ResponsiveText(
                          'Agendar Nueva',
                          baseFontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.green,
                      size: ResponsiveUtils.getIconSize(context, 24),
                    ),
                    ResponsiveHorizontalSpacing(8),
                    Expanded(
                      child: ResponsiveText(
                        'Tiempo Activo',
                        baseFontSize: 18,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                ResponsiveSpacing(16),
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
                ResponsiveSpacing(16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: ResponsiveText(
                      'Cerrar',
                      baseFontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getVerticalSpacing(context, 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveUtils.getHorizontalSpacing(context, 100),
            child: ResponsiveText(
              label,
              baseFontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              baseFontSize: 12,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
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
          ResponsiveSpacing(24),
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
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Historial de Sesiones',
            baseFontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          ResponsiveSpacing(16),

          if (_patient.totalSessions == 0)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: ResponsiveUtils.getIconSize(context, 80),
                    color: Colors.grey[400],
                  ),
                  ResponsiveSpacing(16),
                  ResponsiveText(
                    'Sin sesiones registradas',
                    baseFontSize: 16,
                    color: Colors.grey[600],
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...List.generate(_patient.totalSessions, (index) => 
              Container(
                margin: EdgeInsets.only(
                  bottom: ResponsiveUtils.getVerticalSpacing(context, 12),
                ),
                padding: EdgeInsets.all(
                  ResponsiveUtils.getHorizontalPadding(context),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getBorderRadius(context, 12),
                  ),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.getHorizontalSpacing(context, 8),
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getBorderRadius(context, 8),
                        ),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: AppConstants.primaryColor,
                        size: ResponsiveUtils.getIconSize(context, 20),
                      ),
                    ),
                    ResponsiveHorizontalSpacing(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            'Sesión ${index + 1}',
                            baseFontSize: 16,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          ResponsiveText(
                            _formatDateTime(
                              DateTime.now().subtract(
                                Duration(days: (index + 1) * 7),
                              ),
                            ),
                            baseFontSize: 14,
                            color: Colors.grey[600],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: ResponsiveUtils.getIconSize(context, 16),
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveText(
                  'Notas del Paciente',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                onPressed: () => _addNote(),
                icon: Icon(
                  Icons.add,
                  color: AppConstants.primaryColor,
                  size: ResponsiveUtils.getIconSize(context, 24),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(16),

          if (_patient.notes != null && _patient.notes!.isNotEmpty)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getHorizontalPadding(context),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getBorderRadius(context, 12),
                    ),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            color: AppConstants.primaryColor,
                            size: ResponsiveUtils.getIconSize(context, 20),
                          ),
                          ResponsiveHorizontalSpacing(8),
                          Expanded(
                            child: ResponsiveText(
                              'Notas iniciales',
                              baseFontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryColor,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      ResponsiveSpacing(12),
                      Text(
                        _patient.notes!,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, 14),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ResponsiveSpacing(16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewAllNotes(),
                    icon: Icon(
                      Icons.format_list_bulleted,
                      color: Colors.white,
                      size: ResponsiveUtils.getIconSize(context, 20),
                    ),
                    label: ResponsiveText(
                      'Ver Historial de Notas',
                      baseFontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.getVerticalSpacing(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getBorderRadius(context, 12),
                        ),
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
                  Icon(
                    Icons.note_add,
                    size: ResponsiveUtils.getIconSize(context, 80),
                    color: Colors.grey[400],
                  ),
                  ResponsiveSpacing(16),
                  ResponsiveText(
                    'Sin notas registradas',
                    baseFontSize: 16,
                    color: Colors.grey[600],
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveSpacing(8),
                  ElevatedButton.icon(
                    onPressed: () => _addNote(),
                    icon: Icon(
                      Icons.add,
                      size: ResponsiveUtils.getIconSize(context, 20),
                    ),
                    label: ResponsiveText(
                      'Agregar Primera Nota',
                      baseFontSize: 14,
                    ),
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
      padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getBorderRadius(context, 12),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppConstants.primaryColor,
                size: ResponsiveUtils.getIconSize(context, 20),
              ),
              ResponsiveHorizontalSpacing(8),
              Expanded(
                child: ResponsiveText(
                  title,
                  baseFontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.getVerticalSpacing(context, 12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveUtils.getHorizontalSpacing(context, 120),
            child: ResponsiveText(
              '$label:',
              baseFontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              baseFontSize: 14,
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

  // MÉTODOS PARA COMPLETAR PACIENTE (se mantienen igual)
  void _showCompletePatientDialog() {
    final TextEditingController notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppConstants.primaryColor,
                      size: ResponsiveUtils.getIconSize(context, 24),
                    ),
                    ResponsiveHorizontalSpacing(8),
                    Expanded(
                      child: ResponsiveText(
                        'Completar Tratamiento',
                        baseFontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  '¿Estás seguro de marcar el tratamiento de ${_patient.name} como completado?',
                  baseFontSize: 14,
                ),
                ResponsiveSpacing(16),
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getHorizontalSpacing(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getBorderRadius(context, 8),
                    ),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: ResponsiveUtils.getIconSize(context, 16),
                            color: Colors.blue,
                          ),
                          ResponsiveHorizontalSpacing(4),
                          ResponsiveText(
                            'Información',
                            baseFontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      ResponsiveSpacing(4),
                      ResponsiveText(
                        'Total de sesiones: ${_patient.totalSessions}',
                        baseFontSize: 12,
                      ),
                      if (_patient.lastAppointment != null)
                        ResponsiveText(
                          'Última sesión: ${_formatDateTime(_patient.lastAppointment!)}',
                          baseFontSize: 12,
                        ),
                    ],
                  ),
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  'Notas finales (opcional):',
                  baseFontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                ResponsiveSpacing(8),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Agrega observaciones sobre el cierre del tratamiento...',
                    hintStyle: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, 12),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, 8),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                ResponsiveSpacing(16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: ResponsiveText(
                          'Cancelar',
                          baseFontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _completePatient(notesController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getBorderRadius(context, 8),
                            ),
                          ),
                        ),
                        child: ResponsiveText(
                          'Confirmar',
                          baseFontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getHorizontalSpacing(context, 16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: ResponsiveUtils.getIconSize(context, 64),
                  ),
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  '¡Tratamiento Completado!',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(8),
                ResponsiveText(
                  'El tratamiento de ${_patient.name} ha sido marcado como completado.',
                  baseFontSize: 14,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                    ),
                    child: ResponsiveText(
                      'Entendido',
                      baseFontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}