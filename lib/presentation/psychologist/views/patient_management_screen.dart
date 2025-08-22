// lib/presentation/psychologist/views/patient_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/add_patient_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_detail_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';

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
  List<PatientManagementModel> _allPatients = [];
  List<PatientManagementModel> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadPatients() {
    // TODO: Cargar pacientes reales desde el backend
    _allPatients = [
      PatientManagementModel(
        id: '1',
        name: 'María González',
        email: 'maria.gonzalez@email.com',
        phoneNumber: '+1234567890',
        dateOfBirth: DateTime(1990, 5, 15),
        profilePictureUrl: 'https://via.placeholder.com/60',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        status: PatientStatus.inTreatment,
        notes:
            'Paciente con ansiedad generalizada. Responde bien a la terapia cognitivo-conductual.',
        lastAppointment: DateTime.now().subtract(const Duration(days: 7)),
        nextAppointment: DateTime.now().add(const Duration(days: 7)),
        totalSessions: 8,
        isActive: true,
        contactMethod: ContactMethod.appointment,
      ),
      PatientManagementModel(
        id: '2',
        name: 'Carlos Rodríguez',
        email: 'carlos.rodriguez@email.com',
        phoneNumber: '+0987654321',
        dateOfBirth: DateTime(1985, 8, 22),
        profilePictureUrl: 'https://via.placeholder.com/60',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        status: PatientStatus.pending,
        notes: 'Solicitud de terapia de pareja.',
        totalSessions: 0,
        isActive: true,
        contactMethod: ContactMethod.chat,
      ),
      PatientManagementModel(
        id: '3',
        name: 'Ana Martínez',
        email: 'ana.martinez@email.com',
        phoneNumber: '+1122334455',
        dateOfBirth: DateTime(1995, 12, 3),
        profilePictureUrl: 'https://via.placeholder.com/60',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 14)),
        status: PatientStatus.completed,
        notes:
            'Tratamiento completado exitosamente. Paciente con alta mejoría.',
        lastAppointment: DateTime.now().subtract(const Duration(days: 14)),
        totalSessions: 12,
        isActive: false,
        contactMethod: ContactMethod.manual,
      ),
    ];
    _filteredPatients = List.from(_allPatients);
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
            patient.email.toLowerCase().contains(query) ||
            (patient.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  List<PatientManagementModel> _getPatientsByStatus(PatientStatus? status) {
    if (status == null) return _filteredPatients;
    return _filteredPatients
        .where((patient) => patient.status == status)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
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
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                          ),
                          Text(
                            '${_allPatients.length} pacientes registrados',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPatientScreen(),
                          ),
                        ).then((_) => _loadPatients());
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar pacientes...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.light
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
            child: TabBar(
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
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people),
                      const SizedBox(width: 8),
                      Text('Todos (${_filteredPatients.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⏳'),
                      const SizedBox(width: 8),
                      Text(
                        'Pendientes (${_getPatientsByStatus(PatientStatus.pending).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔄'),
                      const SizedBox(width: 8),
                      Text(
                        'En Tratamiento (${_getPatientsByStatus(PatientStatus.inTreatment).length})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅'),
                      const SizedBox(width: 8),
                      Text(
                        'Completados (${_getPatientsByStatus(PatientStatus.completed).length})',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de pacientes
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPatientsList(_filteredPatients),
                _buildPatientsList(_getPatientsByStatus(PatientStatus.pending)),
                _buildPatientsList(
                  _getPatientsByStatus(PatientStatus.inTreatment),
                ),
                _buildPatientsList(
                  _getPatientsByStatus(PatientStatus.completed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList(List<PatientManagementModel> patients) {
    if (patients.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: Theme.of(context).cardColor,
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
          return _buildPatientTile(patient);
        },
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

  Widget _buildPatientTile(PatientManagementModel patient) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
            backgroundImage: patient.profilePictureUrl != null
                ? NetworkImage(patient.profilePictureUrl!)
                : null,
            child: patient.profilePictureUrl == null
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
                patient.contactMethod.icon,
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
          Container(
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
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            patient.email,
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
              Text(
                '${patient.totalSessions} sesiones',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
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
                Text(
                  'Próxima: ${_formatDate(patient.nextAppointment!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
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
          // Botón para ver citas del paciente
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
                          context
                              .read<AuthBloc>()
                              .state
                              .psychologist
                              ?.username ??
                          '',
                    ),
                  ),
                ),
              );
            },
            tooltip: 'Ver citas del paciente',
          ),
          // Botón para ver detalles
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailScreen(patient: patient),
                ),
              ).then((_) => _loadPatients());
            },
            tooltip: 'Ver detalles',
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailScreen(patient: patient),
          ),
        ).then((_) => _loadPatients());
      },
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