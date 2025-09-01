// lib/presentation/patient/views/patient_appointments_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/session_rating_screen.dart';

class PatientAppointmentsListScreen extends StatefulWidget {
  const PatientAppointmentsListScreen({super.key});

  @override
  State<PatientAppointmentsListScreen> createState() =>
      _PatientAppointmentsListScreenState();
}

class _PatientAppointmentsListScreenState
    extends State<PatientAppointmentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

 @override
void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this);

  // CARGAR CITAS REALES DESDE EL BACKEND
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    context.read<AppointmentBloc>().add(
      LoadAppointmentsEvent(
        userId: currentUser.uid,
        isForPsychologist: false,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 60)),
      ),
    );
  }
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
          'Mis Citas',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
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
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? 'Error desconocido',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        context.read<AppointmentBloc>().add(
                          LoadAppointmentsEvent(
                            userId: currentUser.uid,
                            isForPsychologist: false,
                            startDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            endDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          ),
                        );
                      }
                    },
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
              // Estadísticas resumidas
              _buildStatisticsCard(state),

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
                    fontSize: 12,
                  ),
                  isScrollable: true,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_available, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Próximas (${state.upcomingCount})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Pendientes (${state.pendingCount})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Pasadas (${state.pastCount})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentsList(
                      state.upcomingAppointments,
                      'upcoming',
                    ),
                    _buildAppointmentsList(
                      state.pendingAppointments,
                      'pending',
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
                  icon: Icons.event_available,
                  label: 'Próxima',
                  value: state.upcomingCount.toString(),
                  color: Colors.green,
                ),
              ),
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
          padding: const EdgeInsets.all(12),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
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
          return _buildAppointmentCard(appointment, type);
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String title;
    String subtitle;

    switch (type) {
      case 'upcoming':
        icon = Icons.event_available_outlined;
        title = 'Sin próximas citas';
        subtitle = 'Las citas confirmadas aparecerán aquí';
        break;
      case 'pending':
        icon = Icons.schedule_outlined;
        title = 'Sin citas pendientes';
        subtitle = 'Las citas pendientes de confirmación aparecerán aquí';
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

    return Container(
      color: Theme.of(context).cardColor,
      child: Center(
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
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, String type) {
    return InkWell(
      onTap: () => _handleAppointmentTap(appointment, type),
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
            // Header con estado y fecha
            Row(
              children: [
                Container(
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
                      Text(
                        appointment.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(appointment.status),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'MAÑANA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Información del psicólogo
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppConstants.lightAccentColor.withOpacity(
                    0.3,
                  ),
                  child: Text(
                    appointment.psychologistName.isNotEmpty
                        ? appointment.psychologistName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppConstants.lightAccentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.psychologistName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        appointment.psychologistSpecialty.isNotEmpty
                            ? appointment.psychologistSpecialty
                            : 'Psicología General',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
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

            // Detalles de fecha y hora
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  appointment.formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${appointment.timeRange} (${appointment.formattedDuration})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
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

            // Botón para calificar en citas completadas
            if (type == 'past' &&
                appointment.status == AppointmentStatus.completed) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToRatingScreen(appointment),
                  icon: const Icon(Icons.star_rate, size: 20),
                  label: const Text(
                    'Calificar Sesión',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.lightAccentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleAppointmentTap(AppointmentModel appointment, String type) {
    if (type == 'past') {
      if (appointment.status == AppointmentStatus.completed) {
        // Cita completada - permitir calificar
        _navigateToRatingScreen(appointment);
      } else if (appointment.status == AppointmentStatus.rated) {
        // Cita ya calificada - mostrar detalles con rating
        _showRatedAppointmentDetails(appointment);
      } else {
        // Otras citas pasadas
        _showAppointmentDetails(appointment);
      }
    } else {
      // Para citas futuras o pendientes, mostrar información
      _showAppointmentDetails(appointment);
    }
  }

  void _navigateToRatingScreen(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionRatingScreen(appointment: appointment),
      ),
    );
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detalles de la Cita',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Psicólogo:', appointment.psychologistName),
            _buildDetailRow('Fecha:', appointment.formattedDate),
            _buildDetailRow('Hora:', appointment.timeRange),
            _buildDetailRow('Modalidad:', appointment.type.displayName),
            _buildDetailRow('Estado:', appointment.status.displayName),
            _buildDetailRow('Precio:', '\$${appointment.price.toInt()}'),
            if (appointment.patientNotes?.isNotEmpty == true)
              _buildDetailRow('Notas:', appointment.patientNotes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatedAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cita Calificada ⭐',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Psicólogo:', appointment.psychologistName),
            _buildDetailRow('Fecha:', appointment.formattedDate),
            _buildDetailRow('Hora:', appointment.timeRange),
            _buildDetailRow('Estado:', appointment.status.displayName),
            _buildDetailRow('Precio:', '\$${appointment.price.toInt()}'),
            const SizedBox(height: 16),
            // Sección de calificación
            Text(
              'Tu Calificación:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < (appointment.rating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${appointment.rating ?? 0}/5',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (appointment.ratingComment?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                'Tu Comentario:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.ratingComment!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (appointment.ratedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Calificada el: ${appointment.ratedAt!.day}/${appointment.ratedAt!.month}/${appointment.ratedAt!.year}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppConstants.primaryColor,
              ),
            ),
          ),
        ],
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
        return Colors.green;
      case AppointmentStatus.completed:
        return AppConstants.primaryColor;
      case AppointmentStatus.rated:
        return Colors.amber; 
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.rescheduled:
        return Colors.blue;
    }
  }

  
}
