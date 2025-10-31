// lib/presentation/psychologist/views/patient_management_screen.dart
// ✅ CON BOTÓN DE CHAT AGREGADO

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_detail_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_management_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_management_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_management_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_chat_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_metrics_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/approval_status_blocker.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final psychologistId =
        context.read<AuthBloc>().state.psychologist?.uid ?? '';
    if (psychologistId.isNotEmpty) {
      BlocProvider.of<PatientManagementBloc>(
        context,
      ).add(LoadPatientsEvent(psychologistId: psychologistId));
    }

    _searchController.addListener(() {
      context.read<PatientManagementBloc>().add(
        SearchPatientsEvent(query: _searchController.text),
      );
    });
  }

  List<PatientManagementModel> _getNewPatients(
    List<PatientManagementModel> patients,
  ) {
    return patients
        .where((patient) => (patient.totalSessions ?? 0) == 0)
        .toList();
  }

  List<PatientManagementModel> _getRecurrentPatients(
    List<PatientManagementModel> patients,
  ) {
    return patients
        .where(
          (patient) =>
              (patient.totalSessions ?? 0) > 0 &&
              patient.status == PatientStatus.inTreatment,
        )
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return ApprovalStatusBlocker(
          psychologist: authState.psychologist,
          featureName: 'pacientes',
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: BlocListener<PatientManagementBloc, PatientManagementState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
                }
              },
              child: BlocBuilder<PatientManagementBloc, PatientManagementState>(
                builder: (context, state) {
                  if (state.status == PatientManagementStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state.status == PatientManagementStatus.error) {
                    return Center(
                      child: Text(state.errorMessage ?? 'Ocurrió un error'),
                    );
                  } else {
                    return Column(
                      children: [
                        // Barra de búsqueda y botón agregar
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Theme.of(context).cardColor,
                          child: Column(
                            children: [
                              // Título y botón agregar
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mis Pacientes',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Poppins',
                                              ),
                                        ),
                                        Text(
                                          '${state.allPatients.length} pacientes registrados',
                                          style: Theme.of(context).textTheme.bodySmall
                                              ?.copyWith(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar pacientes...',
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                    fontFamily: 'Poppins',
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(context).brightness == Brightness.light
                                      ? Colors.grey[100]
                                      : Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // TabBar de estados
                        Container(
                          color: Theme.of(context).cardColor,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Vista por Estados',
                                      style: Theme.of(context).textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () =>
                                          _navigateToMetrics(context, null, state),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.analytics,
                                              size: 16,
                                              color: AppConstants.primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Ver Métricas',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppConstants.primaryColor,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TabBar(
                                controller: _tabController,
                                labelColor: AppConstants.primaryColor,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: AppConstants.primaryColor,
                                isScrollable: true,
                                labelStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.normal,
                                ),
                                tabs: [
                                  _buildClickableTab(
                                    context,
                                    'Todos',
                                    state.filteredPatients.length,
                                    Icons.people,
                                    null,
                                    state,
                                  ),
                                  _buildClickableTab(
                                    context,
                                    'Nuevos',
                                    _getNewPatients(state.filteredPatients).length,
                                    Icons.person_add,
                                    null,
                                    state,
                                  ),
                                  _buildClickableTab(
                                    context,
                                    'En tratamiento',
                                    _getRecurrentPatients(
                                      state.filteredPatients,
                                    ).length,
                                    Icons.favorite,
                                    PatientStatus.inTreatment,
                                    state,
                                  ),
                                  _buildClickableTab(
                                    context,
                                    'Completados',
                                    _getPatientsByStatus(
                                      state.filteredPatients,
                                      PatientStatus.completed,
                                    ).length,
                                    Icons.check_circle,
                                    PatientStatus.completed,
                                    state,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Lista de pacientes
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 1: Todos
                              _buildPatientsList(context, state.filteredPatients),

                              // Tab 2: Nuevos (sin sesiones)
                              _buildPatientsList(
                                context,
                                _getNewPatients(state.filteredPatients),
                              ),

                              // Tab 3: Recurrentes (con sesiones y en tratamiento)
                              _buildPatientsList(
                                context,
                                _getRecurrentPatients(state.filteredPatients),
                              ),

                              // Tab 4: Completados
                              _buildPatientsList(
                                context,
                                _getPatientsByStatus(
                                  state.filteredPatients,
                                  PatientStatus.completed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  List<PatientManagementModel> _getPatientsByStatus(
    List<PatientManagementModel> patients,
    PatientStatus status,
  ) {
    return patients.where((patient) => patient.status == status).toList();
  }

  Widget _buildPatientsList(
    BuildContext context,
    List<PatientManagementModel> patients,
  ) {
    if (patients.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: Theme.of(context).cardColor,
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<PatientManagementBloc>().add(RefreshPatientsEvent());
        },
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: patients.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
          itemBuilder: (context, index) {
            final patient = patients[index];
            return _buildPatientTile(context, patient);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No se encontraron pacientes'
                  : 'No hay pacientes en esta categoría',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'Intenta con otro término de búsqueda'
                    : 'Los pacientes aparecerán aquí cuando los agregues',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTile(
    BuildContext context,
    PatientManagementModel patient,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
            backgroundImage:
                patient.profilePictureUrl != null &&
                    patient.profilePictureUrl!.isNotEmpty
                ? NetworkImage(patient.profilePictureUrl!)
                : null,
            child:
                patient.profilePictureUrl == null ||
                    patient.profilePictureUrl!.isEmpty
                ? Text(
                    patient.name.isNotEmpty
                        ? patient.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppConstants.primaryColor,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                patient.contactMethod?.icon ?? '📅',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              patient.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(patient.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                patient.status.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(patient.status),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            patient.email ?? 'Sin email',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${patient.totalSessions ?? 0} sesiones',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (patient.nextAppointment != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Próxima: ${_formatDate(patient.nextAppointment!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.primaryColor,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // Navegar a la pantalla de chat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientChatScreen(
                    patientId: patient.id,
                    patientName: patient.name,
                    patientImageUrl: patient.profilePictureUrl ?? '',
                  ),
                ),
              );
            },
            tooltip: 'Chatear con ${patient.name}',
          ),
          
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: AppConstants.primaryColor,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider<AppointmentBloc>(
                    create: (context) => AppointmentBloc(),
                    child: AppointmentsListScreen(
                      psychologistId:
                          context.read<AuthBloc>().state.psychologist?.username ?? '',
                    ),
                  ),
                ),
              );
            },
            tooltip: 'Ver citas del paciente',
          ),
          
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailScreen(patient: patient),
                ),
              );
              
              if (result == true && mounted) {
                final psychologistId = context.read<AuthBloc>().state.psychologist?.uid ?? '';
                if (psychologistId.isNotEmpty) {
                  context.read<PatientManagementBloc>().add(
                    LoadPatientsEvent(psychologistId: psychologistId),
                  );
                }
              }
            },
            tooltip: 'Ver detalles',
          ),
        ],
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailScreen(patient: patient),
          ),
        );
        
        if (result == true && mounted) {
          final psychologistId = context.read<AuthBloc>().state.psychologist?.uid ?? '';
          if (psychologistId.isNotEmpty) {
            context.read<PatientManagementBloc>().add(
              LoadPatientsEvent(psychologistId: psychologistId),
            );
          }
        }
      },
    );
  }

  Widget _buildClickableTab(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    PatientStatus? status,
    PatientManagementState state,
  ) {
    return GestureDetector(
      onLongPress: () => _navigateToMetrics(context, status, state),
      child: Tab(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status != null
                          ? _getStatusColor(status).withOpacity(0.2)
                          : AppConstants.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status != null
                            ? _getStatusColor(status)
                            : AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMetrics(
    BuildContext context,
    PatientStatus? focusedStatus,
    PatientManagementState state,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientMetricsScreen(
          patients: state.allPatients,
          focusedStatus: focusedStatus,
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Mañana';
    if (difference == -1) return 'Ayer';
    if (difference > 0) return 'En $difference días';
    return 'Hace ${-difference} días';
  }
}