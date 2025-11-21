// lib/presentation/psychologist/views/patient_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
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

// HELPER FUNCTION PARA LIMITAR EL TEXT SCALE FACTOR
double _getConstrainedTextScaleFactor(BuildContext context, {double maxScale = 1.3}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return textScaleFactor.clamp(1.0, maxScale);
}

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
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = true;

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ENVOLVER TODO EN MediaQuery PARA CONTROLAR EL TEXT SCALE FACTOR
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context),
      ),
      child: Builder(
        builder: (context) {
          final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
          final verticalPadding = ResponsiveUtils.getVerticalPadding(context);
          final isMobile = ResponsiveUtils.isMobile(context);
          
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.errorMessage!)),
                        );
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
                          return NestedScrollView(
                            controller: _scrollController,
                            headerSliverBuilder: (context, innerBoxIsScrolled) {
                              return [
                                // Header con búsqueda
                                SliverToBoxAdapter(
                                  child: Container(
                                    padding: EdgeInsets.all(horizontalPadding),
                                    color: Theme.of(context).cardColor,
                                    child: Column(
                                      children: [
                                        // Título
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ResponsiveText(
                                                    'Mis Pacientes',
                                                    baseFontSize: isMobile ? 20 : 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  ResponsiveSpacing(4),
                                                  ResponsiveText(
                                                    '${state.allPatients.length} pacientes registrados',
                                                    baseFontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        ResponsiveSpacing(16),
                                        // Búsqueda
                                        TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Buscar pacientes...',
                                            hintStyle: TextStyle(
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                              fontFamily: 'Poppins',
                                              fontSize: ResponsiveUtils.getFontSize(context, 14),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                              size: ResponsiveUtils.getIconSize(context, 24),
                                            ),
                                            filled: true,
                                            fillColor: Theme.of(context).brightness == Brightness.light
                                                ? Colors.grey[100]
                                                : Colors.grey[800],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(
                                                ResponsiveUtils.getBorderRadius(context, 25),
                                              ),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: horizontalPadding,
                                              vertical: verticalPadding,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // TabBar con métricas
                                SliverToBoxAdapter(
                                  child: Container(
                                    color: Theme.of(context).cardColor,
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPadding,
                                            vertical: verticalPadding,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ResponsiveText(
                                                  'Vista por Estados',
                                                  baseFontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _navigateToMetrics(context, null, state),
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: ResponsiveUtils.getHorizontalSpacing(context, 12),
                                                    vertical: ResponsiveUtils.getVerticalSpacing(context, 6),
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppConstants.primaryColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(
                                                      ResponsiveUtils.getBorderRadius(context, 20),
                                                    ),
                                                    border: Border.all(
                                                      color: AppConstants.primaryColor.withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.analytics,
                                                        size: ResponsiveUtils.getIconSize(context, 16),
                                                        color: AppConstants.primaryColor,
                                                      ),
                                                      ResponsiveHorizontalSpacing(4),
                                                      ResponsiveText(
                                                        'Ver Métricas',
                                                        baseFontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppConstants.primaryColor,
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
                                          labelStyle: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: ResponsiveUtils.getFontSize(context, 13),
                                          ),
                                          unselectedLabelStyle: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.normal,
                                            fontSize: ResponsiveUtils.getFontSize(context, 13),
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
                                              _getRecurrentPatients(state.filteredPatients).length,
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
                                ),
                              ];
                            },
                            body: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildPatientsList(context, state.filteredPatients),
                                _buildPatientsList(
                                  context,
                                  _getNewPatients(state.filteredPatients),
                                ),
                                _buildPatientsList(
                                  context,
                                  _getRecurrentPatients(state.filteredPatients),
                                ),
                                _buildPatientsList(
                                  context,
                                  _getPatientsByStatus(
                                    state.filteredPatients,
                                    PatientStatus.completed,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
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

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PatientManagementBloc>().add(RefreshPatientsEvent());
      },
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.getVerticalPadding(context),
        ),
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
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PatientManagementBloc>().add(RefreshPatientsEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          color: Theme.of(context).cardColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: ResponsiveUtils.getIconSize(context, 80),
                  color: Colors.grey[400],
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  _searchController.text.isNotEmpty
                      ? 'No se encontraron pacientes'
                      : 'No hay pacientes en esta categoría',
                  baseFontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                ResponsiveSpacing(8),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getHorizontalPadding(context) * 2,
                  ),
                  child: ResponsiveText(
                    _searchController.text.isNotEmpty
                        ? 'Intenta con otro término de búsqueda'
                        : 'Los pacientes aparecerán aquí cuando los agregues',
                    baseFontSize: 14,
                    textAlign: TextAlign.center,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientTile(
    BuildContext context,
    PatientManagementModel patient,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isMobileSmall = ResponsiveUtils.isMobileSmall(context);
    final avatarRadius = ResponsiveUtils.getAvatarRadius(context, 28);
    final iconSize = ResponsiveUtils.getIconSize(context, 20);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: ResponsiveUtils.getVerticalPadding(context),
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
            backgroundImage: patient.profilePictureUrl != null &&
                    patient.profilePictureUrl!.isNotEmpty
                ? NetworkImage(patient.profilePictureUrl!)
                : null,
            child: patient.profilePictureUrl == null ||
                    patient.profilePictureUrl!.isEmpty
                ? ResponsiveText(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                    baseFontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
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
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, 12),
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: ResponsiveText(
              patient.name,
              baseFontSize: 16,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (!isMobileSmall) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalSpacing(context, 8),
                  vertical: ResponsiveUtils.getVerticalSpacing(context, 4),
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(patient.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getBorderRadius(context, 12),
                  ),
                ),
                child: ResponsiveText(
                  patient.status.displayName,
                  baseFontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(patient.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSpacing(4),
          if (!isMobileSmall)
            ResponsiveText(
              patient.email ?? 'Sin email',
              baseFontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ResponsiveSpacing(4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: iconSize * 0.7,
                color: Colors.grey[600],
              ),
              ResponsiveHorizontalSpacing(4),
              Flexible(
                child: ResponsiveText(
                  '${patient.totalSessions ?? 0} sesiones',
                  baseFontSize: 12,
                  color: Colors.grey[600],
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (patient.nextAppointment != null && !isMobileSmall) ...[
                ResponsiveHorizontalSpacing(16),
                Icon(
                  Icons.schedule,
                  size: iconSize * 0.7,
                  color: AppConstants.primaryColor,
                ),
                ResponsiveHorizontalSpacing(4),
                Flexible(
                  child: ResponsiveText(
                    'Próxima: ${_formatDate(patient.nextAppointment!)}',
                    baseFontSize: 12,
                    color: AppConstants.primaryColor,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: isMobileSmall
          ? PopupMenuButton(
              icon: Icon(Icons.more_vert, size: iconSize),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: iconSize),
                      ResponsiveHorizontalSpacing(8),
                      const Flexible(
                        child: Text(
                          'Chat',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
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
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: iconSize),
                      ResponsiveHorizontalSpacing(8),
                      const Flexible(
                        child: Text(
                          'Citas',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider<AppointmentBloc>(
                          create: (context) => AppointmentBloc(),
                          child: AppointmentsListScreen(
                            psychologistId: context.read<AuthBloc>().state.psychologist?.username ?? '',
                          ),
                        ),
                      ),
                    );
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward, size: iconSize),
                      ResponsiveHorizontalSpacing(8),
                      const Flexible(
                        child: Text(
                          'Detalles',
                          overflow: TextOverflow.ellipsis,
                        ),
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
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: AppConstants.primaryColor,
                        size: iconSize,
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
                    size: iconSize,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider<AppointmentBloc>(
                          create: (context) => AppointmentBloc(),
                          child: AppointmentsListScreen(
                            psychologistId: context.read<AuthBloc>().state.psychologist?.username ?? '',
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
                    size: iconSize * 0.8,
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
    final iconSize = ResponsiveUtils.getIconSize(context, 18);
    
    return GestureDetector(
      onLongPress: () => _navigateToMetrics(context, status, state),
      child: Tab(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getHorizontalSpacing(context, 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize),
              ResponsiveHorizontalSpacing(6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    title,
                    baseFontSize: 12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getHorizontalSpacing(context, 6),
                      vertical: ResponsiveUtils.getVerticalSpacing(context, 2),
                    ),
                    decoration: BoxDecoration(
                      color: status != null
                          ? _getStatusColor(status).withOpacity(0.2)
                          : AppConstants.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, 10),
                      ),
                    ),
                    child: ResponsiveText(
                      count.toString(),
                      baseFontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status != null
                          ? _getStatusColor(status)
                          : AppConstants.primaryColor,
                      maxLines: 1,
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