// lib/presentation/psychologist/views/appointments_list_screen.dart
// Versión corregida con errores solucionados

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

  // SISTEMA MEJORADO DE RESPONSIVIDAD
  double _getResponsiveFontSize(double baseSize, BuildContext context) {
    final double scaleFactor = MediaQuery.of(context).textScaleFactor;
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    
    // Factor basado en el ancho de la pantalla
    double widthFactor = 1.0;
    if (width < 360) {
      widthFactor = 0.8; // Teléfonos muy pequeños
    } else if (width < 400) {
      widthFactor = 0.9; // Teléfonos pequeños
    } else if (width > 600 && width <= 900) {
      widthFactor = 1.2; // Tabletas
    } else if (width > 900) {
      widthFactor = 1.4; // Tabletas grandes/desktop
    }
    
    // Factor basado en la orientación
    final bool isLandscape = width > height;
    final double orientationFactor = isLandscape ? 0.9 : 1.0;
    
    return (baseSize * widthFactor * orientationFactor * scaleFactor).clamp(8.0, 32.0);
  }

  double _getResponsiveIconSize(double baseSize, BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    double factor = 1.0;
    if (width < 360) {
      factor = 0.7;
    } else if (width < 400) {
      factor = 0.8;
    } else if (width > 600 && width <= 900) {
      factor = 1.3;
    } else if (width > 900) {
      factor = 1.6;
    }
    
    return baseSize * factor;
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return const EdgeInsets.all(8.0);
    } else if (width < 600) {
      return const EdgeInsets.all(12.0);
    } else if (width < 900) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(20.0);
    }
  }

  double _getResponsiveSpacing(double baseSpacing, BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return baseSpacing * 0.7;
    } else if (width > 600 && width < 900) {
      return baseSpacing * 1.2;
    } else if (width >= 900) {
      return baseSpacing * 1.4;
    }
    
    return baseSpacing;
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
            size: _getResponsiveIconSize(24, context),
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
        title: Text(
          'Mis Citas',
          style: TextStyle(
            fontSize: _getResponsiveFontSize(20, context),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              size: _getResponsiveIconSize(24, context),
            ),
            onPressed: _loadAppointments,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<AppointmentBloc, AppointmentState>(
          builder: (context, state) {
            if (state.isLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.isError) {
              return _buildErrorState(state, context);
            }

            return _buildResponsiveLayout(state, context);
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(AppointmentState state, BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;

    if (size.width > 900) {
      return _buildDesktopLayout(state, context);
    } else if (orientation == Orientation.landscape) {
      return _buildLandscapeLayout(state, context);
    } else {
      return _buildPortraitLayout(state, context);
    }
  }

  // LAYOUT PARA ESCRITORIO/TABLETAS GRANDES
  Widget _buildDesktopLayout(AppointmentState state, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel lateral con estadísticas
        Container(
          width: 300,
          padding: _getResponsivePadding(context),
          child: Column(
            children: [
              _buildStatisticsCard(state, context, true),
              SizedBox(height: _getResponsiveSpacing(16, context)),
              _buildVerticalTabs(state, context),
            ],
          ),
        ),

        // Contenido principal
        Expanded(
          child: Padding(
            padding: _getResponsivePadding(context),
            child: _buildAppointmentsList(
              _getCurrentAppointments(state),
              _getCurrentType(),
              context,
              true,
            ),
          ),
        ),
      ],
    );
  }

  // LAYOUT MEJORADO PARA PORTRAIT - HEADER COMPACTO
  Widget _buildPortraitLayout(AppointmentState state, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallPhone = screenWidth < 360;
        final isTablet = screenWidth > 600;
        final isLargeTablet = screenWidth > 900;
        
        return Column(
          children: [
            // Header fijo con estadísticas y tabs - VERSIÓN COMPACTA
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  // Estadísticas más compactas
                  Padding(
                    padding: EdgeInsets.only(
                      left: isLargeTablet ? 16 : (isTablet ? 12 : 8),
                      right: isLargeTablet ? 16 : (isTablet ? 12 : 8),
                      top: isLargeTablet ? 12 : (isTablet ? 8 : 6),
                      bottom: isLargeTablet ? 8 : (isTablet ? 6 : 4),
                    ),
                    child: _buildCompactStatistics(state, context, isTablet, isLargeTablet),
                  ),
                  
                  // Tabs más compactos
                  Container(
                    height: isLargeTablet ? 50 : (isTablet ? 45 : 40),
                    color: Theme.of(context).cardColor,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppConstants.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppConstants.primaryColor,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.normal,
                        fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
                      ),
                      isScrollable: true,
                      tabs: [
                        _buildUltraCompactTabItem(
                          icon: Icons.schedule,
                          label: 'Pendientes',
                          count: state.pendingCount,
                          isTablet: isTablet,
                          isLargeTablet: isLargeTablet,
                        ),
                        _buildUltraCompactTabItem(
                          icon: Icons.event_available,
                          label: 'Próximas',
                          count: state.upcomingCount,
                          isTablet: isTablet,
                          isLargeTablet: isLargeTablet,
                        ),
                        _buildUltraCompactTabItem(
                          icon: Icons.play_arrow,
                          label: 'Progreso',
                          count: state.inProgressCount,
                          isTablet: isTablet,
                          isLargeTablet: isLargeTablet,
                        ),
                        _buildUltraCompactTabItem(
                          icon: Icons.history,
                          label: 'Pasadas',
                          count: state.pastCount,
                          isTablet: isTablet,
                          isLargeTablet: isLargeTablet,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de citas con scroll independiente
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsListWithScroll(
                    state.pendingAppointments,
                    'pending',
                    context,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsListWithScroll(
                    state.upcomingAppointments,
                    'upcoming',
                    context,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsListWithScroll(
                    state.inProgressAppointments,
                    'in_progress',
                    context,
                    isTablet,
                    isLargeTablet,
                  ),
                  _buildAppointmentsListWithScroll(
                    state.pastAppointments,
                    'past',
                    context,
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

  // LAYOUT PARA LANDSCAPE
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
                      context: context,
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                    ),
                    _buildVerticalTab(
                      icon: Icons.event_available,
                      label: 'Próximas',
                      count: state.upcomingCount,
                      index: 1,
                      context: context,
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                    ),
                    _buildVerticalTab(
                      icon: Icons.play_arrow,
                      label: 'En Progreso',
                      count: state.inProgressCount,
                      index: 2,
                      context: context,
                      isTablet: isTablet,
                      isLargeTablet: isLargeTablet,
                    ),
                    _buildVerticalTab(
                      icon: Icons.history,
                      label: 'Pasadas',
                      count: state.pastCount,
                      index: 3,
                      context: context,
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
                    context,
                    true,
                  ),
                  _buildAppointmentsList(
                    state.upcomingAppointments,
                    'upcoming',
                    context,
                    true,
                  ),
                  _buildAppointmentsList(
                    state.inProgressAppointments,
                    'in_progress',
                    context,
                    true,
                  ),
                  _buildAppointmentsList(
                    state.pastAppointments,
                    'past',
                    context,
                    true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // WIDGETS AUXILIARES MEJORADOS

  // Estadísticas más compactas
  Widget _buildCompactStatistics(AppointmentState state, BuildContext context, bool isTablet, bool isLargeTablet) {
    return Container(
      padding: EdgeInsets.all(isLargeTablet ? 12 : (isTablet ? 8 : 6)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactStat(
            icon: Icons.schedule,
            label: 'Pendiente',
            value: state.pendingCount.toString(),
            color: Colors.orange,
            context: context,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
          ),
          _buildCompactStat(
            icon: Icons.event_available,
            label: 'Próxima',
            value: state.upcomingCount.toString(),
            color: Colors.green,
            context: context,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
          ),
          _buildCompactStat(
            icon: Icons.play_arrow,
            label: 'Progreso',
            value: state.inProgressCount.toString(),
            color: Colors.blue,
            context: context,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
          ),
          _buildCompactStat(
            icon: Icons.history,
            label: 'Complet.',
            value: state.pastCount.toString(),
            color: AppConstants.primaryColor,
            context: context,
            isTablet: isTablet,
            isLargeTablet: isLargeTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required BuildContext context,
    required bool isTablet,
    required bool isLargeTablet,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isLargeTablet ? 6 : (isTablet ? 4 : 3)),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isLargeTablet ? 10 : (isTablet ? 8 : 7),
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Tabs ultra compactos
  Widget _buildUltraCompactTabItem({
    required IconData icon,
    required String label,
    required int count,
    required bool isTablet,
    required bool isLargeTablet,
  }) {
    return Tab(
      child: Container(
        constraints: BoxConstraints(
          minWidth: isLargeTablet ? 80 : (isTablet ? 70 : 60),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: isLargeTablet ? 14 : (isTablet ? 12 : 10)
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isLargeTablet ? 10 : (isTablet ? 8 : 6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: isLargeTablet ? 9 : (isTablet ? 7 : 5),
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
    required BuildContext context,
    required bool isTablet,
    required bool isLargeTablet,
  }) {
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isLargeTablet ? 16 : (isTablet ? 12 : 10),
          horizontal: isLargeTablet ? 12 : (isTablet ? 10 : 8),
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
            SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
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

  // ESTADÍSTICAS MEJORADAS
  Widget _buildStatisticsCard(AppointmentState state, BuildContext context, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(_getResponsiveSpacing(12, context)),
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
            isCompact ? 'Resumen' : 'Resumen de Citas',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(isCompact ? 14 : 16, context),
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(8, context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.schedule,
                label: 'Pendiente',
                value: state.pendingCount.toString(),
                color: Colors.orange,
                context: context,
              ),
              _buildStatItem(
                icon: Icons.event_available,
                label: 'Próxima',
                value: state.upcomingCount.toString(),
                color: Colors.green,
                context: context,
              ),
              _buildStatItem(
                icon: Icons.play_arrow,
                label: 'Progreso',
                value: state.inProgressCount.toString(),
                color: Colors.blue,
                context: context,
              ),
              _buildStatItem(
                icon: Icons.history,
                label: 'Completada',
                value: state.pastCount.toString(),
                color: AppConstants.primaryColor,
                context: context,
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
    required BuildContext context,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: _getResponsiveSpacing(2, context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(_getResponsiveSpacing(6, context)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: _getResponsiveIconSize(16, context),
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(4, context)),
            Text(
              value,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(12, context),
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _getResponsiveSpacing(2, context)),
            Text(
              label,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(9, context),
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

  // LISTA DE CITAS MEJORADA CON SCROLL
  Widget _buildAppointmentsListWithScroll(
    List<AppointmentModel> appointments,
    String type,
    BuildContext context,
    bool isTablet,
    bool isLargeTablet,
  ) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type, context, isTablet, isLargeTablet);
    }

    return ListView.builder(
      padding: EdgeInsets.all(isLargeTablet ? 12 : (isTablet ? 8 : 6)),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Container(
          margin: EdgeInsets.only(bottom: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
          child: _buildCompactAppointmentCard(
            appointment, 
            context,
            isTablet,
            isLargeTablet,
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsList(
    List<AppointmentModel> appointments,
    String type,
    BuildContext context,
    bool isLandscape,
  ) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type, context, false, false);
    }

    return ListView.builder(
      padding: _getResponsivePadding(context),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Container(
          margin: EdgeInsets.only(bottom: _getResponsiveSpacing(12, context)),
          child: _buildAppointmentCard(appointment, context, isLandscape),
        );
      },
    );
  }

  // TARJETA DE CITA COMPACTA
  Widget _buildCompactAppointmentCard(
    AppointmentModel appointment, 
    BuildContext context,
    bool isTablet,
    bool isLargeTablet,
  ) {
    final cardPadding = isLargeTablet ? 16.0 : (isTablet ? 12.0 : 8.0);
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _navigateToConfirmationScreen(context, appointment),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header compacto
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeTablet ? 8 : 6, 
                      vertical: isLargeTablet ? 4 : 2
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getShortStatus(appointment.status),
                      style: TextStyle(
                        fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(appointment.status),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (appointment.isToday) ...[
                    SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppConstants.lightAccentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'HOY',
                        style: TextStyle(
                          fontSize: isLargeTablet ? 10 : (isTablet ? 8 : 6),
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
                    size: isLargeTablet ? 20 : (isTablet ? 16 : 14),
                  ),
                ],
              ),
              
              SizedBox(height: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
              
              // Información compacta del paciente
              Row(
                children: [
                  CircleAvatar(
                    radius: isLargeTablet ? 20 : (isTablet ? 16 : 12),
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
                              fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                              fontWeight: FontWeight.bold,
                              color: AppConstants.lightAccentColor,
                              fontFamily: 'Poppins',
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: TextStyle(
                            fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          appointment.patientEmail,
                          style: TextStyle(
                            fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
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
              
              SizedBox(height: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
              
              // Detalles compactos
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.formattedDate,
                      style: TextStyle(
                        fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                        color: Colors.grey[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Icon(
                    Icons.schedule,
                    size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    appointment.timeRange,
                    style: TextStyle(
                      fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                      color: Colors.grey[700],
                      fontFamily: 'Poppins',
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

  Widget _buildAppointmentCard(
    AppointmentModel appointment, 
    BuildContext context,
    bool isLandscape,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _navigateToConfirmationScreen(context, appointment),
        child: Padding(
          padding: EdgeInsets.all(_getResponsiveSpacing(16, context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con estado
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveSpacing(8, context), 
                      vertical: _getResponsiveSpacing(4, context),
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(12, context),
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(appointment.status),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (appointment.isToday) ...[
                    SizedBox(width: _getResponsiveSpacing(8, context)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveSpacing(4, context),
                        vertical: _getResponsiveSpacing(2, context),
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.lightAccentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HOY',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(10, context),
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
                    size: _getResponsiveIconSize(18, context),
                  ),
                ],
              ),
              
              SizedBox(height: _getResponsiveSpacing(12, context)),
              
              // Información del paciente
              Row(
                children: [
                  CircleAvatar(
                    radius: _getResponsiveIconSize(20, context),
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
                              fontSize: _getResponsiveFontSize(16, context),
                              fontWeight: FontWeight.bold,
                              color: AppConstants.lightAccentColor,
                              fontFamily: 'Poppins',
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: _getResponsiveSpacing(12, context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(16, context),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: _getResponsiveSpacing(4, context)),
                        Text(
                          appointment.patientEmail,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(12, context),
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
              
              SizedBox(height: _getResponsiveSpacing(12, context)),
              
              // Detalles de la cita
              Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    text: appointment.formattedDate,
                    context: context,
                  ),
                  SizedBox(height: _getResponsiveSpacing(4, context)),
                  _buildDetailRow(
                    icon: Icons.schedule,
                    text: '${appointment.timeRange} (${appointment.formattedDuration})',
                    context: context,
                  ),
                  SizedBox(height: _getResponsiveSpacing(4, context)),
                  _buildDetailRow(
                    icon: Icons.attach_money,
                    text: '\$${appointment.price.toInt()}',
                    context: context,
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
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: _getResponsiveIconSize(16, context),
          color: Colors.grey[600],
        ),
        SizedBox(width: _getResponsiveSpacing(8, context)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(14, context),
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  // ESTADO VACÍO MEJORADO
  Widget _buildEmptyState(String type, BuildContext context, bool isTablet, bool isLargeTablet) {
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

  // ESTADO DE ERROR MEJORADO
  Widget _buildErrorState(AppointmentState state, BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: _getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: _getResponsiveIconSize(80, context),
              color: Colors.red[400],
            ),
            SizedBox(height: _getResponsiveSpacing(24, context)),
            Text(
              'Error al cargar las citas',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(20, context),
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _getResponsiveSpacing(12, context)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSpacing(32, context),
              ),
              child: Text(
                state.errorMessage ?? 'Error desconocido',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(15, context),
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(24, context)),
            SizedBox(
              width: _getResponsiveIconSize(160, context),
              height: _getResponsiveIconSize(48, context),
              child: ElevatedButton.icon(
                onPressed: _loadAppointments,
                icon: Icon(
                  Icons.refresh, 
                  size: _getResponsiveIconSize(20, context),
                ),
                label: Text(
                  'Reintentar',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(16, context),
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
    );
  }

  // MÉTODOS AUXILIARES
  List<AppointmentModel> _getCurrentAppointments(AppointmentState state) {
    switch (_tabController.index) {
      case 0: return state.pendingAppointments;
      case 1: return state.upcomingAppointments;
      case 2: return state.inProgressAppointments;
      case 3: return state.pastAppointments;
      default: return [];
    }
  }

  String _getCurrentType() {
    switch (_tabController.index) {
      case 0: return 'pending';
      case 1: return 'upcoming';
      case 2: return 'in_progress';
      case 3: return 'past';
      default: return '';
    }
  }

  String _getShortStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pendiente';
      case AppointmentStatus.confirmed:
        return 'Confirmada';
      case AppointmentStatus.in_progress:
        return 'Progreso';
      case AppointmentStatus.cancelled:
        return 'Cancelada';
      case AppointmentStatus.completed:
        return 'Completada';
      case AppointmentStatus.rated:
        return 'Calificada';
      case AppointmentStatus.rescheduled:
        return 'Reprogramada';
      case AppointmentStatus.refunded:
        return 'Reembolsada';
    }
  }

  Widget _buildVerticalTabs(AppointmentState state, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVerticalTab(
            icon: Icons.schedule,
            label: 'Pendientes',
            count: state.pendingCount,
            index: 0,
            context: context,
            isTablet: true,
            isLargeTablet: true,
          ),
          _buildVerticalTab(
            icon: Icons.event_available,
            label: 'Próximas',
            count: state.upcomingCount,
            index: 1,
            context: context,
            isTablet: true,
            isLargeTablet: true,
          ),
          _buildVerticalTab(
            icon: Icons.play_arrow,
            label: 'En Progreso',
            count: state.inProgressCount,
            index: 2,
            context: context,
            isTablet: true,
            isLargeTablet: true,
          ),
          _buildVerticalTab(
            icon: Icons.history,
            label: 'Pasadas',
            count: state.pastCount,
            index: 3,
            context: context,
            isTablet: true,
            isLargeTablet: true,
          ),
        ],
      ),
    );
  }

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