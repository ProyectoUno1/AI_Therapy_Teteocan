// lib/presentation/psychologist/views/appointments_list_screen.dart
// Versión completamente responsiva basada en el código del paciente

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointment_confirmation_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/approval_status_blocker.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  final String psychologistId;

  const AppointmentsListScreen({super.key, required this.psychologistId});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _didInitBloc = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitBloc) {
      _loadAppointments();
      _didInitBloc = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAppointments() {
    context.read<AppointmentBloc>().add(
      LoadAppointmentsEvent(
        userId: widget.psychologistId,
        isForPsychologist: true,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return ApprovalStatusBlocker(
          psychologist: authState.psychologist,
          featureName: 'citas',
          child: _buildAppointmentsContent(context),
        );
      },
    );
  }

  Widget _buildAppointmentsContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: 24,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PsychologistHomeScreen(),
              ),
            );
          },
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Text(
              'Mis Citas',
              style: TextStyle(
                fontSize: constraints.maxWidth < 360 ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontFamily: 'Poppins',
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              size: 24,
            ),
            onPressed: _loadAppointments,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return BlocBuilder<AppointmentBloc, AppointmentState>(
              builder: (context, state) {
                if (state.isLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.isError) {
                  return _buildErrorState(state, orientation);
                }

                return _buildResponsiveLayout(state, orientation);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(AppointmentState state, Orientation orientation) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLandscape = orientation == Orientation.landscape;
        final isTablet = screenWidth > 600;
        final isLargeTablet = screenWidth > 900;

        if (isLandscape) {
          return _buildLandscapeLayout(state, context);
        } else {
          return _buildPortraitLayout(state, context);
        }
      },
    );
  }

  // LAYOUT PARA PORTRAIT - ESTRUCTURA SIMPLE Y ROBUSTA
  Widget _buildPortraitLayout(AppointmentState state, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallPhone = screenWidth < 360;
        final isTablet = screenWidth > 600;
        final isLargeTablet = screenWidth > 900;
        
        return Column(
          children: [
            // Estadísticas
            Padding(
              padding: EdgeInsets.only(
                left: isLargeTablet ? 20 : (isTablet ? 16 : 12),
                right: isLargeTablet ? 20 : (isTablet ? 16 : 12),
                top: isLargeTablet ? 16 : (isTablet ? 12 : 8),
                bottom: isLargeTablet ? 16 : (isTablet ? 12 : 8),
              ),
              child: _buildStatisticsCard(state, false, isTablet, screenWidth),
            ),
            
            // Tabs
            Container(
              height: isLargeTablet ? 60 : (isTablet ? 55 : 50),
              color: Theme.of(context).cardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: AppConstants.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppConstants.primaryColor,
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: isLargeTablet ? 14 : (isTablet ? 12 : (isSmallPhone ? 8 : 10)),
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.normal,
                  fontSize: isLargeTablet ? 14 : (isTablet ? 12 : (isSmallPhone ? 8 : 10)),
                ),
                isScrollable: true,
                tabs: [
                  _buildCompactTabItem(
                    icon: Icons.schedule,
                    label: 'Pendientes',
                    count: state.pendingCount,
                    isSmallPhone: isSmallPhone,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,
                  ),
                  _buildCompactTabItem(
                    icon: Icons.event_available,
                    label: 'Próximas',
                    count: state.upcomingCount,
                    isSmallPhone: isSmallPhone,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,
                  ),
                  _buildCompactTabItem(
                    icon: Icons.play_arrow,
                    label: 'En Progreso',
                    count: state.inProgressCount,
                    isSmallPhone: isSmallPhone,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,
                  ),
                  _buildCompactTabItem(
                    icon: Icons.history,
                    label: 'Pasadas',
                    count: state.pastCount,
                    isSmallPhone: isSmallPhone,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,
                  ),
                ],
              ),
            ),
            
            // Lista de citas
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsList(
                    state.pendingAppointments,
                    'pending',
                    false,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsList(
                    state.upcomingAppointments,
                    'upcoming',
                    false,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsList(
                    state.inProgressAppointments,
                    'in_progress',
                    false,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsList(
                    state.pastAppointments,
                    'past',
                    false,
                    isTablet,
                    isLargeTablet,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // LAYOUT PARA LANDSCAPE - TABS VERTICALES
  Widget _buildLandscapeLayout(AppointmentState state, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        final isLargeTablet = screenWidth > 900;
        
        return Row(
          children: [
            // Tabs verticales
            Container(
              width: isLargeTablet ? 200 : (isTablet ? 160 : 140),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(right: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildVerticalTab(
                      icon: Icons.schedule,
                      label: 'Pendientes',
                      count: state.pendingCount,
                      index: 0,
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                    ),
                    _buildVerticalTab(
                      icon: Icons.event_available,
                      label: 'Próximas',
                      count: state.upcomingCount,
                      index: 1,
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                    ),
                    _buildVerticalTab(
                      icon: Icons.play_arrow,
                      label: 'En Progreso',
                      count: state.inProgressCount,
                      index: 2,
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                    ),
                    _buildVerticalTab(
                      icon: Icons.history,
                      label: 'Pasadas',
                      count: state.pastCount,
                      index: 3,
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenido
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsList(
                    state.pendingAppointments,
                    'pending',
                    true,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsList(
                    state.upcomingAppointments,
                    'upcoming',
                    true,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsList(
                    state.inProgressAppointments,
                    'in_progress',
                    true,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsList(
                    state.pastAppointments,
                    'past',
                    true,
                    isTablet,
                    isLargeTablet,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // WIDGETS AUXILIARES

  Widget _buildCompactTabItem({
    required IconData icon,
    required String label,
    required int count,
    required bool isSmallPhone,
    required bool isTablet,
    required bool isLargeTablet,
  }) {
    return Tab(
      child: Container(
        constraints: BoxConstraints(
          minWidth: isLargeTablet ? 100 : (isTablet ? 90 : 80),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: isLargeTablet ? 16 : (isTablet ? 14 : (isSmallPhone ? 10 : 12))
            ),
            SizedBox(width: isSmallPhone ? 2 : 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isLargeTablet ? 12 : (isTablet ? 10 : (isSmallPhone ? 7 : 8))
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: isSmallPhone ? 1 : 2),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: isLargeTablet ? 10 : (isTablet ? 8 : (isSmallPhone ? 5 : 6))
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalTab({
    required IconData icon,
    required String label,
    required int count,
    required int index,
    required bool isTablet,
    required bool isLargeTablet,
  }) {
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isLargeTablet ? 20 : (isTablet ? 16 : 14),
          horizontal: isLargeTablet ? 16 : (isTablet ? 12 : 10),
        ),
        decoration: BoxDecoration(
          color: _tabController.index == index 
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: isLargeTablet ? 24 : (isTablet ? 20 : 18),
              color: _tabController.index == index 
                  ? AppConstants.primaryColor
                  : Colors.grey,
            ),
            SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                      fontWeight: _tabController.index == index 
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _tabController.index == index 
                          ? AppConstants.primaryColor
                          : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '($count)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                      color: _tabController.index == index 
                          ? AppConstants.primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ESTADÍSTICAS COMPACTAS Y SEGURAS
  Widget _buildStatisticsCard(AppointmentState state, bool isLandscape, bool isTablet, double screenWidth) {
    final isLargeTablet = screenWidth > 900;
    
    return Container(
      padding: EdgeInsets.all(
        isLandscape 
          ? (isLargeTablet ? 8 : (isTablet ? 6 : 4))
          : (isLargeTablet ? 16 : (isTablet ? 12 : 10))
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLandscape ? 'Resumen' : 'Resumen de Citas',
            style: TextStyle(
              fontSize: isLandscape 
                ? (isLargeTablet ? 14 : (isTablet ? 12 : 10))
                : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: isLandscape ? 4 : (isLargeTablet ? 14 : (isTablet ? 10 : 8))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactStatItem(
                icon: Icons.schedule,
                label: 'Pendiente',
                value: state.pendingCount.toString(),
                color: Colors.orange,
                isLandscape: isLandscape,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
              ),
              _buildCompactStatItem(
                icon: Icons.event_available,
                label: 'Próxima',
                value: state.upcomingCount.toString(),
                color: Colors.green,
                isLandscape: isLandscape,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
              ),
              _buildCompactStatItem(
                icon: Icons.play_arrow,
                label: 'Progreso',
                value: state.inProgressCount.toString(),
                color: Colors.blue,
                isLandscape: isLandscape,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
              ),
              _buildCompactStatItem(
                icon: Icons.history,
                label: 'Completada',
                value: state.pastCount.toString(),
                color: AppConstants.primaryColor,
                isLandscape: isLandscape,
                isTablet: isTablet,
                isLargeTablet: isLargeTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isLandscape,
    required bool isTablet,
    required bool isLargeTablet,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isLargeTablet ? 4 : (isTablet ? 3 : 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isLargeTablet ? 8 : (isTablet ? 6 : (isLandscape ? 4 : 5))),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: isLargeTablet ? 20 : (isTablet ? 18 : (isLandscape ? 14 : 16)),
              ),
            ),
            SizedBox(height: isLargeTablet ? 6 : (isTablet ? 4 : (isLandscape ? 2 : 3))),
            Text(
              value,
              style: TextStyle(
                fontSize: isLargeTablet ? 16 : (isTablet ? 14 : (isLandscape ? 12 : 13)),
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isLargeTablet ? 12 : (isTablet ? 10 : (isLandscape ? 8 : 9)),
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // LISTA DE CITAS
  Widget _buildAppointmentsList(
    List<AppointmentModel> appointments,
    String type,
    bool isLandscape,
    bool isTablet,
    bool isLargeTablet,
  ) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type, isLandscape, isTablet, isLargeTablet);
    }

    return ListView.builder(
      padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Container(
          margin: EdgeInsets.only(
            bottom: isLargeTablet ? 16 : (isTablet ? 12 : 8)
          ),
          child: _buildAppointmentCard(
            appointment, 
            isLandscape, 
            isTablet,
            isLargeTablet,
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment, 
    bool isLandscape, 
    bool isTablet,
    bool isLargeTablet,
  ) {
    final cardPadding = isLargeTablet ? 24.0 : (isTablet ? 20.0 : (isLandscape ? 12.0 : 16.0));
    final avatarRadius = isLargeTablet ? 32.0 : (isTablet ? 28.0 : (isLandscape ? 20.0 : 24.0));
    final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : (isLandscape ? 14.0 : 16.0));
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _navigateToConfirmationScreen(context, appointment),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con estado
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeTablet ? 12 : 8, 
                      vertical: isLargeTablet ? 8 : 4
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        fontSize: isLargeTablet ? 16 : (isTablet ? 14 : (isLandscape ? 10 : 12)),
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(appointment.status),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (appointment.isToday) ...[
                    SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.lightAccentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HOY',
                        style: TextStyle(
                          fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
                          fontWeight: FontWeight.bold,
                          color: AppConstants.lightAccentColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    appointment.type == AppointmentType.online
                        ? Icons.videocam
                        : Icons.location_on,
                    color: appointment.type == AppointmentType.online
                        ? AppConstants.lightAccentColor
                        : Colors.orange,
                    size: isLargeTablet ? 28 : (isTablet ? 24 : (isLandscape ? 16 : 18)),
                  ),
                ],
              ),
              
              SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
              
              // Información del paciente
              Row(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
                    backgroundImage: appointment.patientProfileUrl != null
                        ? NetworkImage(appointment.patientProfileUrl!)
                        : null,
                    child: appointment.patientProfileUrl == null
                        ? Text(
                            appointment.patientName.isNotEmpty
                                ? appointment.patientName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: isLargeTablet ? 22 : (isTablet ? 18 : (isLandscape ? 14 : 16)),
                              fontWeight: FontWeight.bold,
                              color: AppConstants.lightAccentColor,
                              fontFamily: 'Poppins',
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          appointment.patientEmail,
                          style: TextStyle(
                            fontSize: isLargeTablet ? 16 : (isTablet ? 14 : (isLandscape ? 11 : 12)),
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
              
              // Detalles de la cita
              Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    text: appointment.formattedDate,
                    isLandscape: isLandscape,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,
                  ),
                  SizedBox(height: 4),
                  _buildDetailRow(
                    icon: Icons.schedule,
                    text: '${appointment.timeRange} (${appointment.formattedDuration})',
                    isLandscape: isLandscape,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,
                  ),
                  SizedBox(height: 4),
                  _buildDetailRow(
                    icon: Icons.attach_money,
                    text: '\$${appointment.price.toInt()}',
                    isLandscape: isLandscape,
                    isTablet: isTablet,
                    isLargeTablet: isLargeTablet,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required bool isLandscape,
    required bool isTablet,
    required bool isLargeTablet,
  }) {
    final iconSize = isLargeTablet ? 24.0 : (isTablet ? 20.0 : (isLandscape ? 14.0 : 16.0));
    final fontSize = isLargeTablet ? 18.0 : (isTablet ? 16.0 : (isLandscape ? 12.0 : 14.0));
    
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Colors.grey[600],
        ),
        SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  // ESTADO VACÍO
  Widget _buildEmptyState(String type, bool isLandscape, bool isTablet, bool isLargeTablet) {
    IconData icon;
    String title;
    String subtitle;

    switch (type) {
      case 'pending':
        icon = Icons.schedule_outlined;
        title = 'Sin citas pendientes';
        subtitle = 'Las nuevas solicitudes aparecerán aquí';
        break;
      case 'upcoming':
        icon = Icons.event_available_outlined;
        title = 'Sin citas próximas';
        subtitle = 'Las citas confirmadas aparecerán aquí';
        break;
      case 'in_progress':
        icon = Icons.play_arrow_outlined;
        title = 'Sin citas en progreso';
        subtitle = 'Las citas que inicies aparecerán aquí';
        break;
      case 'past':
        icon = Icons.history_outlined;
        title = 'Sin historial de citas';
        subtitle = 'Las citas completadas aparecerán aquí';
        break;
      default:
        icon = Icons.event_note_outlined;
        title = 'Sin citas';
        subtitle = 'No hay citas para mostrar';
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: isLargeTablet ? 80 : (isTablet ? 64 : 48), 
                color: Colors.grey[400]
              ),
              SizedBox(height: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
              Text(
                title,
                style: TextStyle(
                  fontSize: isLargeTablet ? 22 : (isTablet ? 20 : 18),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeTablet ? 32 : (isTablet ? 24 : 16)
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                    color: Colors.grey[500],
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ESTADO DE ERROR
  Widget _buildErrorState(AppointmentState state, Orientation orientation) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = orientation == Orientation.landscape;
        final isTablet = constraints.maxWidth > 600;
        final isLargeTablet = constraints.maxWidth > 900;
        
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(isLargeTablet ? 40 : (isTablet ? 32 : 20)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: isLargeTablet ? 100 : (isTablet ? 80 : (isLandscape ? 60 : 64)),
                    color: Colors.red[400],
                  ),
                  SizedBox(height: isLargeTablet ? 32 : (isTablet ? 24 : 16)),
                  Text(
                    'Error al cargar las citas',
                    style: TextStyle(
                      fontSize: isLargeTablet ? 26 : (isTablet ? 22 : (isLandscape ? 18 : 20)),
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeTablet ? 40 : (isTablet ? 32 : 16)
                    ),
                    child: Text(
                      state.errorMessage ?? 'Error desconocido',
                      style: TextStyle(
                        fontSize: isLargeTablet ? 18 : (isTablet ? 16 : (isLandscape ? 14 : 15)),
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isLargeTablet ? 32 : (isTablet ? 24 : 20)),
                  SizedBox(
                    width: isLargeTablet ? 240 : (isTablet ? 200 : 160),
                    height: isLargeTablet ? 60 : (isTablet ? 56 : 48),
                    child: ElevatedButton.icon(
                      onPressed: _loadAppointments,
                      icon: Icon(
                        Icons.refresh, 
                        size: isLargeTablet ? 28 : (isTablet ? 24 : 20)
                      ),
                      label: Text(
                        'Reintentar',
                        style: TextStyle(
                          fontSize: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.lightAccentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // NAVEGACIÓN
  void _navigateToConfirmationScreen(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          BlocProvider.value(
            value: context.read<AppointmentBloc>(),
            child: AppointmentConfirmationScreen(appointment: appointment),
          ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    if (result == true) {
      _loadAppointments();
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.in_progress:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return AppConstants.primaryColor;
      case AppointmentStatus.rated:
        return Colors.amber;
      case AppointmentStatus.rescheduled:
        return Colors.blue;
      case AppointmentStatus.refunded:
        return Colors.purple;
    }
  }
}