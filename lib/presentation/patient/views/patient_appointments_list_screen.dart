// lib/presentation/patient/views/patient_appointments_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/core/services/appointment_service.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_state.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/session_rating_screen.dart';

class PatientAppointmentsListScreen extends StatefulWidget {
  final String? highlightAppointmentId; 
  final String? filterStatus;
  final VoidCallback? onGoToHome;
  const PatientAppointmentsListScreen({super.key, this.highlightAppointmentId, this.filterStatus, this.onGoToHome});

  @override
  State<PatientAppointmentsListScreen> createState() =>
      _PatientAppointmentsListScreenState();
}

class _PatientAppointmentsListScreenState
    extends State<PatientAppointmentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showStatistics = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    final shouldShow = scrollOffset <= 50;

    if (shouldShow != _showStatistics) {
      setState(() {
        _showStatistics = shouldShow;
      });
    }
  }

  bool _canCancelAppointment(AppointmentModel appointment) {
    if (appointment.status != AppointmentStatus.pending && 
        appointment.status != AppointmentStatus.confirmed) {
      return false;
    }
    
    final now = DateTime.now();
    final appointmentDate = appointment.scheduledDateTime;
    final difference = appointmentDate.difference(now);
    
    return difference.inHours >= 72;
  }

  String _getCancelRestrictionMessage(AppointmentModel appointment) {
    final now = DateTime.now();
    final appointmentDate = appointment.scheduledDateTime;
    final difference = appointmentDate.difference(now);
    
    if (difference.inHours < 72) {
      final hoursRemaining = difference.inHours;
      final daysRemaining = (hoursRemaining / 24).floor();
      
      if (daysRemaining < 1) {
        return 'Solo puedes cancelar con al menos 3 días de anticipación.\n\nFaltan menos de 24 horas para tu cita.';
      } else if (daysRemaining < 3) {
        return 'Solo puedes cancelar con al menos 3 días de anticipación.\n\nFaltan $daysRemaining día${daysRemaining == 1 ? '' : 's'} para tu cita.';
      }
    }
    
    return 'Puedes cancelar esta cita';
  }

  void _showCancelAppointmentDialog(AppointmentModel appointment) {
    final canCancel = _canCancelAppointment(appointment);
    final message = _getCancelRestrictionMessage(appointment);
    
    if (!canCancel) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se puede cancelar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final reasonController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async {
                reasonController.dispose();
                return true;
              },
              child: AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancelar Cita',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
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
                        '¿Estás seguro de que deseas cancelar esta cita?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Psicólogo: ${appointment.psychologistName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: ${appointment.formattedDate}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hora: ${appointment.formattedTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Motivo de cancelación (opcional)',
                          labelStyle: const TextStyle(fontFamily: 'Poppins'),
                          hintText: 'Ej: Cambio de planes, emergencia, etc.',
                          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      reasonController.dispose();
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      'No, mantener cita',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final reason = reasonController.text.trim();
                      Navigator.pop(dialogContext);
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        reasonController.dispose();
                        _processCancelAppointment(appointment, reason);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Sí, cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processCancelAppointment(AppointmentModel appointment, String reason) async {
    BuildContext? loadingContext;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loadingContext = ctx;
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Cancelando cita...',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    
    try {
      final service = AppointmentService();
      
      await service.cancelAppointment(
        appointmentId: appointment.id,
        reason: reason.isEmpty ? 'Sin motivo especificado' : reason,
      );
      
      if (loadingContext != null && mounted) {
        Navigator.of(loadingContext!).pop();
      }
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        context.read<AppointmentBloc>().add(
          LoadAppointmentsEvent(
            userId: currentUser.uid,
            isForPsychologist: false,
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now().add(const Duration(days: 60)),
          ),
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cita cancelada exitosamente',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (loadingContext != null && mounted) {
        Navigator.of(loadingContext!).pop();
      }
      
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: $errorMessage',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
            size: 24,
          ),
          onPressed: () {
          // ✅ CORRECCIÓN: Usar callback si existe para volver al tab Home, sino, usar pop normal
          if (widget.onGoToHome != null) {
            widget.onGoToHome!(); 
          } else {
            Navigator.pop(context); 
          }
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

  Widget _buildCompactVerticalTab({
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
        vertical: isLargeTablet ? 16 : (isTablet ? 14 : 12), 
        horizontal: isLargeTablet ? 12 : (isTablet ? 10 : 8)
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
            size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
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
                    fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
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
                    fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
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

  // Layout para landscape
  

Widget _buildLandscapeLayout(AppointmentState state, BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final isTablet = screenWidth > 600;
      final isLargeTablet = screenWidth > 900;
      
      return Column(
        children: [
          // Tarjeta de estadísticas ELIMINADA en landscape
          // Ya no se muestra en orientación horizontal
          
          // Contenido principal - EXPANDED para ocupar todo el espacio
          Expanded(
            child: Row(
              children: [
                // Tabs verticales compactos (Fixed WIDTH) con mejor manejo de altura
                Container(
                  width: isLargeTablet ? 180 : (isTablet ? 150 : 120),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(right: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(), // Mejor scroll
                    child: IntrinsicHeight( // Ajusta altura al contenido
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCompactVerticalTab(
                            icon: Icons.event_available,
                            label: 'Próximas',
                            count: state.upcomingCount,
                            index: 0,
                            isTablet: isTablet,
                            isLargeTablet: isLargeTablet,
                          ),
                          _buildCompactVerticalTab(
                            icon: Icons.schedule,
                            label: 'Pendientes',
                            count: state.pendingCount,
                            index: 1,
                            isTablet: isTablet,
                            isLargeTablet: isLargeTablet,
                          ),
                          _buildCompactVerticalTab(
                            icon: Icons.history,
                            label: 'Pasadas',
                            count: state.pastCount,
                            index: 2,
                            isTablet: isTablet,
                            isLargeTablet: isLargeTablet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Contenido de citas CON SCROLL
                Expanded(
                  child: _buildLandscapeContent(state, isTablet, isLargeTablet),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}


  // Widget para tabs verticales
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
          vertical: isLargeTablet ? 24 : (isTablet ? 20 : 16), 
          horizontal: isLargeTablet ? 20 : (isTablet ? 16 : 12)
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: isLargeTablet ? 28 : (isTablet ? 24 : 20),
              color: _tabController.index == index 
                  ? AppConstants.primaryColor
                  : Colors.grey,
            ),
            SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
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
                  SizedBox(height: 4),
                  Text(
                    '($count)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
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

  // Layout para portrait - CORREGIDO COMPLETAMENTE
  Widget _buildPortraitLayout(AppointmentState state, BuildContext context) {
  // Nota: Asumo que las variables _tabController, _buildAppBar, _buildCompactTabItem, y _buildAppointmentsList
  // están definidas en el State del widget principal.
  
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final screenHeight = constraints.maxHeight; // No usado en este layout, pero se mantiene.
      final isSmallPhone = screenWidth < 360;
      final isTablet = screenWidth > 600;
      final isLargeTablet = screenWidth > 900;
      
      return Column(
        children: [
          // 2. Estadísticas - ¡CORRECCIÓN CLAVE AQUÍ!
          // Se reemplaza el Container con BoxConstraints.maxHeight por un Padding.
          // Esto permite que el _buildStatisticsCard use MainAxisSize.min para ajustarse
          // y evita el overflow en pantallas pequeñas.
          Padding(
            padding: EdgeInsets.only(
              left: isLargeTablet ? 20 : (isTablet ? 16 : 12),
              right: isLargeTablet ? 20 : (isTablet ? 16 : 12),
              top: isLargeTablet ? 16 : (isTablet ? 12 : 8),
              bottom: isLargeTablet ? 16 : (isTablet ? 12 : 8),
            ),
            // Asegúrate de que _buildStatisticsCard use MainAxisSize.min internamente (ver siguiente corrección)
            child: _buildStatisticsCard(state, false, isTablet, screenWidth), 
          ),
          
          // 3. Tabs
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
                  icon: Icons.event_available,
                  label: 'Próximas',
                  count: state.upcomingCount,
                  isSmallPhone: isSmallPhone,
                  isTablet: isTablet,
                  isLargeTablet: isLargeTablet,
                ),
                _buildCompactTabItem(
                  icon: Icons.schedule,
                  label: 'Pendientes',
                  count: state.pendingCount,
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
          
          // 4. Lista de citas - EXPANDED (Esto es correcto, pero necesitaba el ajuste de las estadísticas)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(
                  state.upcomingAppointments,
                  'upcoming',
                  false,
                  isTablet,
                  isLargeTablet,
                ),
                _buildAppointmentsList(
                  state.pendingAppointments,
                  'pending',
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
          Text(
            label,
            style: TextStyle(
              fontSize: isLargeTablet ? 12 : (isTablet ? 10 : (isSmallPhone ? 7 : 8))
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

  // Widget de estadísticas COMPLETAMENTE CORREGIDO
  Widget _buildStatisticsCard(AppointmentState state, bool isLandscape, bool isTablet, double screenWidth) {
  final isLargeTablet = screenWidth > 900;
  
  return Container(
    padding: EdgeInsets.all(
      isLandscape 
        ? (isLargeTablet ? 8 : (isTablet ? 6 : 4))  // Más compacto en landscape
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
        // Título más pequeño en landscape
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
              icon: Icons.event_available,
              label: 'Próxima',
              value: state.upcomingCount.toString(),
              color: Colors.green,
              isLandscape: isLandscape,
              isTablet: isTablet,
              isLargeTablet: isLargeTablet,
            ),
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

Widget _buildSimpleStatItem({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // También para seguridad aquí
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6), 
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2), 
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
          maxLines: 1, // Limita la etiqueta a una línea
          overflow: TextOverflow.ellipsis, // Usa puntos suspensivos si se desborda
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
        mainAxisSize: MainAxisSize.min, // IMPORTANTE
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

  // Item de estadística COMPLETAMENTE CORREGIDO
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isLandscape,
    required bool isTablet,
    required bool isLargeTablet,
    required bool isSmallPhone,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(
            isLargeTablet ? 14 : (isTablet ? 12 : (isSmallPhone ? 8 : 10))
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: isLargeTablet ? 28 : (isTablet ? 24 : (isSmallPhone ? 18 : 20)),
          ),
        ),
        SizedBox(height: isSmallPhone ? 6 : 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isLargeTablet ? 22 : (isTablet ? 20 : (isSmallPhone ? 16 : 18)),
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isLargeTablet ? 14 : (isTablet ? 13 : (isSmallPhone ? 10 : 11)),
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Lista de citas
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
          type, 
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
    String type, 
    bool isLandscape, 
    bool isTablet,
    bool isLargeTablet,
  ) {
    final canCancel = _canCancelAppointment(appointment);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _handleAppointmentTap(appointment, type),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardPadding = isLargeTablet ? 24.0 : (isTablet ? 20.0 : (isLandscape ? 12.0 : 16.0));
            final avatarRadius = isLargeTablet ? 32.0 : (isTablet ? 28.0 : (isLandscape ? 20.0 : 24.0));
            final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : (isLandscape ? 14.0 : 16.0));
            final detailFontSize = isLargeTablet ? 18.0 : (isTablet ? 16.0 : (isLandscape ? 12.0 : 14.0));
            final buttonHeight = isLargeTablet ? 56.0 : (isTablet ? 50.0 : (isLandscape ? 40.0 : 44.0));
            
            return Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCardHeader(appointment, isLandscape, isTablet, isLargeTablet),
                  SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                  _buildPsychologistInfo(appointment, isLandscape, isTablet, isLargeTablet, avatarRadius, titleFontSize),
                  SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                  _buildAppointmentDetails(appointment, isLandscape, isTablet, isLargeTablet, detailFontSize),

                  if ((type == 'upcoming' || type == 'pending') || 
                      (type == 'past' && appointment.status == AppointmentStatus.completed)) 
                    SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),

                  if (type == 'upcoming' || type == 'pending') 
                    _buildCancelButton(appointment, canCancel, isLandscape, isTablet, isLargeTablet, buttonHeight, detailFontSize),

                  if (type == 'past' && appointment.status == AppointmentStatus.completed)
                    _buildRatingButton(appointment, isLandscape, isTablet, isLargeTablet, buttonHeight, detailFontSize),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardHeader(AppointmentModel appointment, bool isLandscape, bool isTablet, bool isLargeTablet) {
    return Row(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildPsychologistInfo(AppointmentModel appointment, bool isLandscape, bool isTablet, bool isLargeTablet, double avatarRadius, double titleFontSize) {
    return Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
          child: Text(
            appointment.psychologistName.isNotEmpty
                ? appointment.psychologistName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontSize: isLargeTablet ? 22 : (isTablet ? 18 : (isLandscape ? 14 : 16)),
              fontWeight: FontWeight.bold,
              color: AppConstants.lightAccentColor,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(width: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.psychologistName,
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
                appointment.psychologistSpecialty.isNotEmpty
                    ? appointment.psychologistSpecialty
                    : 'Psicología General',
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
    );
  }

  Widget _buildAppointmentDetails(AppointmentModel appointment, bool isLandscape, bool isTablet, bool isLargeTablet, double detailFontSize) {
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.calendar_today,
          text: appointment.formattedDate,
          isLandscape: isLandscape,
          isTablet: isTablet,
          isLargeTablet: isLargeTablet,
          fontSize: detailFontSize,
        ),
        SizedBox(height: 4),
        _buildDetailRow(
          icon: Icons.schedule,
          text: '${appointment.timeRange} (${appointment.formattedDuration})',
          isLandscape: isLandscape,
          isTablet: isTablet,
          isLargeTablet: isLargeTablet,
          fontSize: detailFontSize,
        ),
        SizedBox(height: 4),
        _buildDetailRow(
          icon: Icons.attach_money,
          text: '\${appointment.price.toInt()}',
          isLandscape: isLandscape,
          isTablet: isTablet,
          isLargeTablet: isLargeTablet,
          fontSize: detailFontSize,
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required bool isLandscape,
    required bool isTablet,
    required bool isLargeTablet,
    required double fontSize,
  }) {
    final iconSize = isLargeTablet ? 24.0 : (isTablet ? 20.0 : (isLandscape ? 14.0 : 16.0));
    
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

  Widget _buildCancelButton(AppointmentModel appointment, bool canCancel, bool isLandscape, bool isTablet, bool isLargeTablet, double buttonHeight, double fontSize) {
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: () => _showCancelAppointmentDialog(appointment),
        style: OutlinedButton.styleFrom(
          foregroundColor: canCancel ? Colors.red : Colors.orange,
          side: BorderSide(
            color: canCancel ? Colors.red : Colors.orange,
          ),
        ),
        child: Text(
          canCancel ? 'Cancelar Cita' : 'No se puede cancelar',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton(AppointmentModel appointment, bool isLandscape, bool isTablet, bool isLargeTablet, double buttonHeight, double fontSize) {
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: () => _navigateToRatingScreen(appointment),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.lightAccentColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          'Calificar Sesión',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

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
                      onPressed: () {
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
                      },
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

  void _handleAppointmentTap(AppointmentModel appointment, String type) {
    if (type == 'past') {
      if (appointment.status == AppointmentStatus.completed) {
        _navigateToRatingScreen(appointment);
      } else if (appointment.status == AppointmentStatus.rated) {
        _showRatedAppointmentDetails(appointment);
      } else {
        _showAppointmentDetails(appointment);
      }
    } else {
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
        title: const Text(
          'Detalles de la Cita',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRowDialog('Psicólogo:', appointment.psychologistName),
              _buildDetailRowDialog('Fecha:', appointment.formattedDate),
              _buildDetailRowDialog('Hora:', appointment.timeRange),
              _buildDetailRowDialog('Modalidad:', appointment.type.displayName),
              _buildDetailRowDialog('Estado:', appointment.status.displayName),
              _buildDetailRowDialog('Precio:', '\${appointment.price.toInt()}'),
              if (appointment.patientNotes?.isNotEmpty == true)
                _buildDetailRowDialog('Notas:', appointment.patientNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.primaryColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowDialog(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
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
        title: const Text(
          'Cita Calificada ⭐',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRowDialog('Psicólogo:', appointment.psychologistName),
              _buildDetailRowDialog('Fecha:', appointment.formattedDate),
              _buildDetailRowDialog('Hora:', appointment.timeRange),
              _buildDetailRowDialog('Estado:', appointment.status.displayName),
              _buildDetailRowDialog('Precio:', '\${appointment.price.toInt()}'),
              const SizedBox(height: 16),
              const Text(
                'Tu Calificación:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              if (appointment.ratingComment?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Text(
                  'Tu Comentario:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
              if (appointment.ratedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Calificada el: ${appointment.ratedAt!.day}/${appointment.ratedAt!.month}/${appointment.ratedAt!.year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.primaryColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type, bool isLandscape, bool isTablet, bool isLargeTablet) {
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

  return Center(
    child: SingleChildScrollView( // ⬅️ AGREGADO
      child: Padding(
        padding: EdgeInsets.all(isLargeTablet ? 32 : (isTablet ? 24 : 16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ⬅️ AGREGADO - CRÍTICO
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

  Widget _buildLandscapeContent(AppointmentState state, bool isTablet, bool isLargeTablet) {
  return TabBarView(
    controller: _tabController,
    children: [
      _buildLandscapeAppointmentsList(
        state.upcomingAppointments,
        'upcoming',
        isTablet,
        isLargeTablet,
      ),
      _buildLandscapeAppointmentsList(
        state.pendingAppointments,
        'pending',
        isTablet,
        isLargeTablet,
      ),
      _buildLandscapeAppointmentsList(
        state.pastAppointments,
        'past',
        isTablet,
        isLargeTablet,
      ),
    ],
  );
}
Widget _buildLandscapeAppointmentsList(
  List<AppointmentModel> appointments,
  String type,
  bool isTablet,
  bool isLargeTablet,
) {
  if (appointments.isEmpty) {
    return _buildLandscapeEmptyState(type, isTablet, isLargeTablet);
  }

  return ListView.builder(
    controller: _scrollController,
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
          type, 
          true, // isLandscape
          isTablet,
          isLargeTablet,
        ),
      );
    },
  );
}

// ESTADO VACÍO LANDSCAPE CON SCROLL
  // patient_appointments_list_screen.dart (Aproximadamente Línea 1228)

Widget _buildLandscapeEmptyState(String type, bool isTablet, bool isLargeTablet) {
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

  return Center(
    child: SingleChildScrollView( // ⬅️ AGREGADO
      child: Padding(
        padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ⬅️ AGREGADO - CRÍTICO
          children: [
            Icon(
              icon, 
              size: isLargeTablet ? 48 : (isTablet ? 40 : 32),
              color: Colors.grey[400]
            ),
            SizedBox(height: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
            Text(
              title,
              style: TextStyle(
                fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeTablet ? 16 : (isTablet ? 12 : 8)
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 9),
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // ⬅️ AGREGADO
                overflow: TextOverflow.ellipsis, // ⬅️ AGREGADO
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildAppBar(double screenWidth, bool isTablet, bool isLargeTablet) {
    return Padding(
      padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      child: Text(
        'Mis Citas',
        style: TextStyle(
          fontSize: isLargeTablet ? 20 : (isTablet ? 18 : 16),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isLargeTablet, bool isTablet) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCompactVerticalTab(
            icon: Icons.event_available,
            label: 'Próximas',
            count: BlocProvider.of<AppointmentBloc>(context).state.upcomingCount,
            index: 0,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
          ),
          _buildCompactVerticalTab(
            icon: Icons.schedule,
            label: 'Pendientes',
            count: BlocProvider.of<AppointmentBloc>(context).state.pendingCount,
            index: 1,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
          ),
          _buildCompactVerticalTab(
            icon: Icons.history,
            label: 'Pasadas',
            count: BlocProvider.of<AppointmentBloc>(context).state.pastCount,
            index: 2,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
          ),
        ],
      ),
    );
  }

  List<Widget> _tabViews(AppointmentState state, double screenWidth, bool isTablet, bool isLargeTablet) {
    return [
      _buildAppointmentsList(
        state.upcomingAppointments,
        'upcoming',
        true,
        isTablet,
        isLargeTablet,
      ),
      _buildAppointmentsList(
        state.pendingAppointments,
        'pending',
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
    ];
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
      case AppointmentStatus.refunded:
        return Colors.purple;
    }
  }
}