// lib/presentation/psychologist/views/appointments_list_screen.dart
// Con bloqueo por estado de aprobación

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointment_confirmation_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/approval_status_blocker.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

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
        // Aplicar bloqueo si el estado no es 'APPROVED'
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
          ),
          onPressed: () => Navigator.pop(context),
          onLongPress: _loadAppointments,
        ),
        title: Text(
          'Mis Citas',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: BlocBuilder<AppointmentBloc, AppointmentState>(
        builder: (context, state) {
          if (state.isLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar las citas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center, 
                  ),
                  const SizedBox(height: 8),
                  Padding( 
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      state.errorMessage ?? 'Error desconocido',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis, 
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAppointments,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.lightAccentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildStatisticsCard(state),
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
                    fontSize: 11, 
                  ),
                  isScrollable: true,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 14), 
                          const SizedBox(width: 4),
                          Text('Pendientes (${state.pendingCount})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_available, size: 14), 
                          const SizedBox(width: 4),
                          Text('Próximas (${state.upcomingCount})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, size: 14), 
                          const SizedBox(width: 4),
                          Text('Progreso (${state.inProgressCount})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 14), 
                          const SizedBox(width: 4),
                          Text('Pasadas (${state.pastCount})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentsList(
                      state.pendingAppointments,
                      'pending',
                    ),
                    _buildAppointmentsList(
                      state.upcomingAppointments,
                      'upcoming',
                    ),
                    _buildAppointmentsList(
                      state.inProgressAppointments,
                      'in_progress',
                    ),
                    _buildAppointmentsList(state.pastAppointments, 'past'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard(AppointmentState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Citas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule,
                  label: 'Pendiente',
                  value: state.pendingCount.toString(),
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.event_available,
                  label: 'Próxima',
                  value: state.upcomingCount.toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.play_arrow,
                  label: 'En Progreso',
                  value: state.inProgressCount.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.history,
                  label: 'Completada',
                  value: state.pastCount.toString(),
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
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
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center, // SOLUCIÓN OVERFLOW
          maxLines: 1, // SOLUCIÓN OVERFLOW
          overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(
    List<AppointmentModel> appointments,
    String type,
  ) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type);
    }

    return Container(
      color: Theme.of(context).cardColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
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
        icon = Icons.calendar_today_outlined;
        title = 'Sin citas';
        subtitle = 'No hay citas para mostrar';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center, 
          ),
          const SizedBox(height: 8),
          Padding( 
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return InkWell(
      onTap: () {
        _navigateToConfirmationScreen(context, appointment);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(appointment.status).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Expanded( 
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appointment.status.icon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Flexible( 
                          child: Text(
                            appointment.status.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(appointment.status),
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8), 
                if (appointment.isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.lightAccentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'HOY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.lightAccentColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                else if (appointment.isTomorrow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, 
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'MAÑANA',
                      style: TextStyle(
                        fontSize: 9, 
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
                  backgroundImage: appointment.patientProfileUrl != null
                      ? NetworkImage(appointment.patientProfileUrl!)
                      : null,
                  child: appointment.patientProfileUrl == null
                      ? Text(
                          appointment.patientName.isNotEmpty
                              ? appointment.patientName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppConstants.lightAccentColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded( 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis, 
                        maxLines: 1, 
                      ),
                      Text(
                        appointment.patientEmail,
                        style: TextStyle(
                          fontSize: 12,
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
                  appointment.type == AppointmentType.online
                      ? Icons.videocam
                      : Icons.location_on,
                  color: appointment.type == AppointmentType.online
                      ? AppConstants.lightAccentColor
                      : Colors.orange,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded( 
                  child: Text(
                    appointment.formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis, 
                    maxLines: 1, 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
           
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded( 
                  child: Text(
                    '${appointment.timeRange} (${appointment.formattedDuration})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis, 
                    maxLines: 1, 
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${appointment.price.toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
           
            if (appointment.patientNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appointment.patientNotes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2, // SOLUCIÓN OVERFLOW
                  overflow: TextOverflow.ellipsis, // SOLUCIÓN OVERFLOW
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
    }
  }

  void _navigateToConfirmationScreen(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<AppointmentBloc>(),
          child: AppointmentConfirmationScreen(appointment: appointment),
        ),
      ),
    );

    // Si la pantalla de confirmación regresa con un resultado 'true',
    // significa que una acción fue completada y se debe refrescar la lista.
    if (result == true) {
      _loadAppointments();
    }
  }
}