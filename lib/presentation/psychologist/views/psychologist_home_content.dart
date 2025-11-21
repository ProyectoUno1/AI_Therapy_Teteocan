// lib/presentation/psychologist/views/psychologist_home_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/data/models/article_model.dart';
import 'package:ai_therapy_teteocan/data/models/session_model.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/article_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/dashboard_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/dashboard_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/dashboard_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/add_article_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/edit_article_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/widgets/article_limit_card.dart';
import 'package:ai_therapy_teteocan/data/models/article_limit_info.dart';

class PsychologistHomeContent extends StatefulWidget {
  const PsychologistHomeContent({super.key});

  @override
  State<PsychologistHomeContent> createState() =>
      _PsychologistHomeContentState();
}

class _PsychologistHomeContentState extends State<PsychologistHomeContent> {
  @override
  void initState() {
    super.initState();
    final String? psychologistId = context
        .read<AuthBloc>()
        .state
        .psychologist
        ?.uid;

    if (psychologistId != null) {
      context.read<ArticleBloc>().add(const LoadArticles());
      context.read<DashboardBloc>().add(LoadDashboardData(psychologistId));
    }
  }

  // ============================================
  // MÉTODOS AUXILIARES PARA RESPONSIVIDAD
  // ============================================
  
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.all(12.0);
    } else if (width < 600) {
      return const EdgeInsets.all(16.0);
    } else if (width < 900) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final width = MediaQuery.of(context).size.width;
    
    double scaledSize = baseSize;
    
    if (width < 360) {
      scaledSize = baseSize * 0.9;
    } else if (width > 900) {
      scaledSize = baseSize * 1.05;
    }
    
    final limitedScale = textScaleFactor.clamp(0.8, 1.3);
    
    return scaledSize * limitedScale;
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return baseSpacing * 0.75;
    } else if (width < 600) {
      return baseSpacing;
    } else {
      return baseSpacing * 1.2;
    }
  }

  double _getResponsiveIconSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return baseSize * 0.85;
    }
    return baseSize;
  }

  // ============================================
  // DIÁLOGOS Y MODALES
  // ============================================

  void _showArticleLimitDialog(BuildContext context, ArticleLimitInfo limitInfo) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth < 360 ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: _getResponsiveIconSize(context, 28),
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(context, 12)),
              Expanded(
                child: Text(
                  'Límite alcanzado',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: _getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
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
                  'Has alcanzado el límite de ${limitInfo.maxLimit} artículos activos.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: _getResponsiveFontSize(context, 14),
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(context, 16)),
                Container(
                  padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.secondaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: _getResponsiveIconSize(context, 20),
                            color: AppConstants.secondaryColor,
                          ),
                          SizedBox(width: _getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: Text(
                              'Para crear un nuevo artículo:',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: _getResponsiveFontSize(context, 13),
                                fontWeight: FontWeight.w600,
                                color: AppConstants.secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _getResponsiveSpacing(context, 8)),
                      Text(
                        '• Elimina artículos antiguos\n• Archiva borradores no utilizados',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: _getResponsiveFontSize(context, 12),
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppConstants.secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: _getResponsiveFontSize(context, 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showArticleLimitDetailsBottomSheet(
    BuildContext context,
    ArticleLimitInfo limitInfo,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: _getResponsivePadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 20)),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(_getResponsiveSpacing(context, 10)),
                        decoration: BoxDecoration(
                          color: AppConstants.secondaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          color: AppConstants.secondaryColor,
                          size: _getResponsiveIconSize(context, 24),
                        ),
                      ),
                      SizedBox(width: _getResponsiveSpacing(context, 12)),
                      Expanded(
                        child: Text(
                          'Límite de Artículos',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 24)),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = screenWidth < 600;
                      
                      if (isCompact) {
                        return Column(
                          children: [
                            _StatCard(
                              label: 'Publicados',
                              value: '${limitInfo.currentCount}',
                              icon: Icons.article,
                              color: AppConstants.secondaryColor,
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, 12)),
                            _StatCard(
                              label: 'Disponibles',
                              value: '${limitInfo.remaining}',
                              icon: Icons.add_circle_outline,
                              color: Colors.green,
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, 12)),
                            _StatCard(
                              label: 'Límite Total',
                              value: '${limitInfo.maxLimit}',
                              icon: Icons.workspace_premium,
                              color: Colors.orange,
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Publicados',
                                value: '${limitInfo.currentCount}',
                                icon: Icons.article,
                                color: AppConstants.secondaryColor,
                              ),
                            ),
                            SizedBox(width: _getResponsiveSpacing(context, 12)),
                            Expanded(
                              child: _StatCard(
                                label: 'Disponibles',
                                value: '${limitInfo.remaining}',
                                icon: Icons.add_circle_outline,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: _getResponsiveSpacing(context, 12)),
                            Expanded(
                              child: _StatCard(
                                label: 'Límite Total',
                                value: '${limitInfo.maxLimit}',
                                icon: Icons.workspace_premium,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 24)),
                  Container(
                    padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Uso actual',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Text(
                              '${limitInfo.percentage}%',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 18),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: _getLimitColor(limitInfo.percentage),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 12)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: limitInfo.percentage / 100,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getLimitColor(limitInfo.percentage),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 24)),
                  Container(
                    padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppConstants.secondaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: _getResponsiveIconSize(context, 20),
                              color: AppConstants.secondaryColor,
                            ),
                            SizedBox(width: _getResponsiveSpacing(context, 8)),
                            Expanded(
                              child: Text(
                                '¿Por qué hay un límite?',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: AppConstants.secondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _getResponsiveSpacing(context, 8)),
                        Text(
                          'El límite de artículos ayuda a mantener contenido de calidad y relevante. '
                          'Puedes eliminar artículos antiguos para crear nuevos.',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 12),
                            fontFamily: 'Poppins',
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 24)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: _getResponsiveSpacing(context, 16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Entendido',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: _getResponsiveFontSize(context, 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getLimitColor(int percentage) {
    if (percentage >= 100) return Colors.red;
    if (percentage >= 80) return Colors.orange;
    if (percentage >= 50) return AppConstants.lightAccentColor;
    return AppConstants.secondaryColor;
  }

  Future<void> _updateAvailability(bool isAvailable) async {
    try {
      final String? psychologistId = context
          .read<AuthBloc>()
          .state
          .psychologist
          ?.uid;
      
      if (psychologistId == null) return;

      await FirebaseFirestore.instance
          .collection('psychologists')
          .doc(psychologistId)
          .update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvailable
                  ? 'Ahora estás disponible para nuevas sesiones'
                  : 'Ya no apareces en la búsqueda de pacientes',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar disponibilidad: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
// ============================================
  // BUILD PRINCIPAL
  // ============================================

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final responsivePadding = _getResponsivePadding(context);
    
    return RefreshIndicator(
      onRefresh: () async {
        final String? psychologistId = context
            .read<AuthBloc>()
            .state
            .psychologist
            ?.uid;
        if (psychologistId != null) {
          context.read<ArticleBloc>().add(const LoadArticles());
          context.read<DashboardBloc>().add(RefreshDashboard(psychologistId));
        }
      },
      child: SingleChildScrollView(
        padding: responsivePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // SECCIÓN: RESUMEN DE HOY
            // ============================================
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, dashboardState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      'Resumen de hoy',
                      suffixWidget: Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: _getResponsiveIconSize(context, 14),
                              color: AppConstants.secondaryColor,
                            ),
                            SizedBox(width: _getResponsiveSpacing(context, 4)),
                            Flexible(
                              child: Text(
                                '${dashboardState.weekSessions} sesiones esta semana',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(context, 12),
                                  color: AppConstants.secondaryColor,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 8)),

                    if (dashboardState.status == DashboardStatus.loading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(_getResponsiveSpacing(context, 32)),
                          child: const CircularProgressIndicator(),
                        ),
                      )
                    else if (dashboardState.todaySessions.isEmpty)
                      _buildEmptyTodaySessionsCard(context)
                    else
                      ...dashboardState.todaySessions
                          .map((appointment) => _SessionCard(appointment: appointment))
                          .toList(),
                  ],
                );
              },
            ),
            SizedBox(height: _getResponsiveSpacing(context, 24)),

            // ============================================
            // SECCIÓN: TU HORARIO
            // ============================================
            _buildSectionHeader(
              context,
              'Tu horario',
              suffixWidget: CircleAvatar(
                backgroundColor: AppConstants.secondaryColor,
                radius: _getResponsiveIconSize(context, 16),
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: _getResponsiveIconSize(context, 18),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función de agregar sesión próximamente'),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tight(
                    Size(
                      _getResponsiveIconSize(context, 32),
                      _getResponsiveIconSize(context, 32),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, 8)),
            _buildScheduleCalendar(),
            SizedBox(height: _getResponsiveSpacing(context, 24)),

            // ============================================
            // SECCIÓN: NOTAS Y SESIONES RECIENTES
            // ============================================
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, dashboardState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      'Notas y sesiones recientes',
                      suffixText: screenWidth > 600 ? 'Ver todas' : null,
                      onTapSuffix: () {},
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 8)),

                    if (dashboardState.recentSessions.isEmpty)
                      _buildEmptyRecentSessionsCard(context)
                    else
                      ...dashboardState.recentSessions
                          .map((appointment) => _NoteSessionCard(appointment: appointment))
                          .toList(),
                  ],
                );
              },
            ),
            SizedBox(height: _getResponsiveSpacing(context, 24)),

            // ============================================
            // SECCIÓN: DISPONIBILIDAD
            // ============================================
            _buildSectionHeader(context, 'Disponibilidad'),
            SizedBox(height: _getResponsiveSpacing(context, 8)),
            _buildAvailabilityCard(),
            SizedBox(height: _getResponsiveSpacing(context, 24)),

            // ============================================
            // SECCIÓN: TUS ARTÍCULOS
            // ============================================
            BlocBuilder<ArticleBloc, ArticleState>(
              builder: (context, state) {
                final limitInfo = state is ArticlesLoaded ? state.limitInfo : null;
                final canCreate = limitInfo?.canCreateMore ?? true;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      'Tus artículos',
                      suffixWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (limitInfo != null) 
                            ArticleLimitBadge(limitInfo: limitInfo),
                          SizedBox(width: _getResponsiveSpacing(context, 8)),
                          CircleAvatar(
                            backgroundColor: canCreate
                                ? AppConstants.secondaryColor
                                : Colors.grey[400],
                            radius: _getResponsiveIconSize(context, 16),
                            child: IconButton(
                              icon: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: _getResponsiveIconSize(context, 18),
                              ),
                              onPressed: canCreate
                                  ? () {
                                      final String? currentUserId =
                                          FirebaseAuth.instance.currentUser?.uid;
                                      if (currentUserId != null) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => AddArticleScreen(
                                              psychologistId: currentUserId,
                                            ),
                                          ),
                                        ).then((_) {
                                          context.read<ArticleBloc>().add(
                                            const LoadArticles(),
                                          );
                                        });
                                      }
                                    }
                                  : () {
                                      if (limitInfo != null) {
                                        _showArticleLimitDialog(context, limitInfo);
                                      }
                                    },
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tight(
                                Size(
                                  _getResponsiveIconSize(context, 32),
                                  _getResponsiveIconSize(context, 32),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 8)),
                    if (limitInfo != null)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: _getResponsiveSpacing(context, 8),
                        ),
                        child: ArticleLimitCard(
                          limitInfo: limitInfo,
                          onTapDetails: () {
                            _showArticleLimitDetailsBottomSheet(context, limitInfo);
                          },
                        ),
                      ),

                    _buildArticlesList(),
                  ],
                );
              },
            ),
            SizedBox(height: _getResponsiveSpacing(context, 24)),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BUILDERS DE WIDGETS ESPECÍFICOS
  // ============================================

  Widget _buildEmptyTodaySessionsCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: _getResponsiveIconSize(context, 48),
                color: Colors.grey[400],
              ),
              SizedBox(height: _getResponsiveSpacing(context, 8)),
              Text(
                'No tienes sesiones programadas para hoy',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                  fontSize: _getResponsiveFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecentSessionsCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSpacing(context, 24)),
        child: Center(
          child: Text(
            'No hay sesiones recientes',
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontSize: _getResponsiveFontSize(context, 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesList() {
    return BlocConsumer<ArticleBloc, ArticleState>(
      listener: (context, state) {
        if (state is ArticleOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: _getResponsiveSpacing(context, 8)),
                  const Text('Operación exitosa'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is ArticleOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  SizedBox(width: _getResponsiveSpacing(context, 8)),
                  Expanded(
                    child: Text(
                      state.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Cerrar',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ArticlesLoading) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(_getResponsiveSpacing(context, 32)),
              child: const CircularProgressIndicator(),
            ),
          );
        } else if (state is ArticlesLoaded) {
          if (state.articles.isEmpty) {
            return _buildEmptyArticlesState();
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final cardWidth = screenWidth < 360 ? 180.0 : screenWidth < 600 ? 220.0 : 250.0;
          final listHeight = screenWidth < 360 ? 260.0 : 280.0;

          return SizedBox(
            height: listHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.articles.length,
              itemBuilder: (context, index) {
                final article = state.articles[index];
                return SizedBox(
                  width: cardWidth,
                  child: _ArticleCard(
                    article: article,
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditArticleScreen(
                            article: article,
                          ),
                        ),
                      ).then((_) {
                        context.read<ArticleBloc>().add(const LoadArticles());
                      });
                    },
                    onDelete: () {
                      _showDeleteConfirmation(context, article);
                    },
                  ),
                );
              },
            ),
          );
        } else if (state is ArticlesError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(_getResponsiveSpacing(context, 32)),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: _getResponsiveIconSize(context, 64),
                    color: Colors.red[300],
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 16)),
                  Text(
                    'Error al cargar artículos',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 16),
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 8)),
                  Text(
                    state.message ?? 'Error desconocido',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 12),
                      color: Colors.red[600],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _getResponsiveSpacing(context, 8)),
                  TextButton(
                    onPressed: () {
                      context.read<ArticleBloc>().add(const LoadArticles());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyArticlesState() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsiveSpacing(context, 32)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.article_outlined,
                size: _getResponsiveIconSize(context, 48),
                color: AppConstants.secondaryColor,
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, 16)),
            Text(
              'No tienes artículos aún',
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, 8)),
            Text(
              'Comparte tu conocimiento creando tu primer artículo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 13),
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: _getResponsiveSpacing(context, 16)),
            ElevatedButton.icon(
              onPressed: () {
                final String? currentUserId =
                    FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddArticleScreen(
                        psychologistId: currentUserId,
                      ),
                    ),
                  ).then((_) {
                    context.read<ArticleBloc>().add(const LoadArticles());
                  });
                }
              },
              icon: Icon(Icons.add, size: _getResponsiveIconSize(context, 20)),
              label: Text(
                'Crear artículo',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 14),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.secondaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSpacing(context, 24),
                  vertical: _getResponsiveSpacing(context, 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
// ============================================
  // CALENDARIO DE HORARIOS
  // ============================================

  Widget _buildScheduleCalendar() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashboardState) {
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final screenWidth = MediaQuery.of(context).size.width;

        final Map<int, int> appointmentsPerDay = {};

        for (var appointment in dashboardState.allMonthSessions) {
          final day = appointment.scheduledDateTime.day;
          appointmentsPerDay[day] = (appointmentsPerDay[day] ?? 0) + 1;
        }

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
            child: Column(
              children: [
                // Botones de toggle
                LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonWidth = constraints.maxWidth / 3 - 8;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: _ScheduleToggleButton(
                            label: 'Día',
                            isSelected: false,
                            onTap: () {},
                            
                          ),
                        ),
                        SizedBox(width: _getResponsiveSpacing(context, 4)),
                        Flexible(
                          child: _ScheduleToggleButton(
                            label: 'Semana',
                            isSelected: true,
                            onTap: () {},
                            
                          ),
                        ),
                        SizedBox(width: _getResponsiveSpacing(context, 4)),
                        Flexible(
                          child: _ScheduleToggleButton(
                            label: 'Mes',
                            isSelected: false,
                            onTap: () {},
                            
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: _getResponsiveSpacing(context, 16)),
                
                // Header del mes
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSpacing(context, 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.arrow_left,
                        color: Colors.grey[600],
                        size: _getResponsiveIconSize(context, 24),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy', 'es').format(now),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            fontSize: _getResponsiveFontSize(context, 16),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_right,
                        color: Colors.grey[600],
                        size: _getResponsiveIconSize(context, 24),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _getResponsiveSpacing(context, 16)),

                // Días de la semana (headers)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                    return Center(
                      child: Text(
                        weekdays[index],
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 11),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: _getResponsiveSpacing(context, 8)),

                // Días del mes
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isCurrentDay = (day == now.day);
                    final appointmentCount = appointmentsPerDay[day] ?? 0;
                    final hasAppointments = appointmentCount > 0;

                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrentDay
                            ? AppConstants.secondaryColor.withOpacity(0.2)
                            : hasAppointments
                            ? AppConstants.lightAccentColor.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrentDay
                            ? Border.all(
                                color: AppConstants.secondaryColor,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isCurrentDay
                                  ? AppConstants.secondaryColor
                                  : hasAppointments
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight: isCurrentDay || hasAppointments
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontFamily: 'Poppins',
                              fontSize: _getResponsiveFontSize(context, 13),
                            ),
                          ),
                          if (hasAppointments)
                            Positioned(
                              bottom: screenWidth < 360 ? 1 : 2,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth < 360 ? 3 : 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.lightAccentColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$appointmentCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _getResponsiveFontSize(context, 8),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: _getResponsiveSpacing(context, 12)),

                // Leyenda
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: _getResponsiveSpacing(context, 16),
                  runSpacing: _getResponsiveSpacing(context, 8),
                  children: const [
                    _CalendarLegendItem(
                      color: AppConstants.secondaryColor,
                      label: 'Hoy',
                    ),
                    _CalendarLegendItem(
                      color: AppConstants.lightAccentColor,
                      label: 'Con citas',
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

  // ============================================
  // CARD DE DISPONIBILIDAD
  // ============================================

  Widget _buildAvailabilityCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAvailable = authState.psychologist?.isAvailable ?? false;
        final screenWidth = MediaQuery.of(context).size.width;
        
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(_getResponsiveSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Disponible para sesiones',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 15),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: _getResponsiveSpacing(context, 8)),
                    Transform.scale(
                      scale: screenWidth < 360 ? 0.85 : 1.0,
                      child: Switch(
                        value: isAvailable,
                        onChanged: (bool value) async {
                          await _updateAvailability(value);
                          context.read<AuthBloc>().add(CheckAuthStatus());
                        },
                        activeColor: AppConstants.secondaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getResponsiveSpacing(context, 8)),
                Text(
                  isAvailable
                      ? 'Los pacientes pueden encontrarte y solicitar sesiones.'
                      : 'No aparecerás en la búsqueda de pacientes.',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 12),
                    color: Colors.grey[700],
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // DIÁLOGO DE CONFIRMACIÓN DE ELIMINACIÓN
  // ============================================

  void _showDeleteConfirmation(BuildContext context, Article article) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BlocConsumer<ArticleBloc, ArticleState>(
          listener: (context, state) {
            if (state is ArticleOperationSuccess) {
              Navigator.of(dialogContext).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: _getResponsiveSpacing(context, 8)),
                      const Expanded(
                        child: Text('Artículo eliminado exitosamente'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is ArticleOperationError) {
              Navigator.of(dialogContext).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      SizedBox(width: _getResponsiveSpacing(context, 8)),
                      Expanded(child: Text('Error: ${state.message}')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          builder: (context, state) {
            final isDeleting = state is ArticleOperationInProgress;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: _getResponsiveIconSize(context, 24),
                    ),
                  ),
                  SizedBox(width: _getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: Text(
                      'Eliminar artículo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: _getResponsiveFontSize(context, 18),
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
                      '¿Estás seguro de que deseas eliminar este artículo?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 12)),
                    Container(
                      padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.article,
                            color: Colors.grey[600],
                            size: _getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: _getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: Text(
                              article.title,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: _getResponsiveFontSize(context, 13),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 12)),
                    Container(
                      padding: EdgeInsets.all(_getResponsiveSpacing(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: _getResponsiveIconSize(context, 20),
                          ),
                          SizedBox(width: _getResponsiveSpacing(context, 8)),
                          Expanded(
                            child: Text(
                              'Esta acción no se puede deshacer',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: _getResponsiveFontSize(context, 12),
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDeleting) ...[
                      SizedBox(height: _getResponsiveSpacing(context, 16)),
                      Center(
                        child: Column(
                          children: [
                            SizedBox(
                              width: _getResponsiveIconSize(context, 30),
                              height: _getResponsiveIconSize(context, 30),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: _getResponsiveSpacing(context, 12)),
                            Text(
                              'Eliminando artículo...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: _getResponsiveFontSize(context, 12),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!isDeleting) ...[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ArticleBloc>().add(
                        DeleteArticle(articleId: article.id!),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Eliminar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // ============================================
  // HEADER DE SECCIÓN
  // ============================================

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? suffixText,
    VoidCallback? onTapSuffix,
    Widget? suffixWidget,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _getResponsiveSpacing(context, 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveFontSize(context, 18),
                fontFamily: 'Poppins',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (suffixText != null)
            GestureDetector(
              onTap: onTapSuffix,
              child: Text(
                suffixText,
                style: TextStyle(
                  color: AppConstants.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveFontSize(context, 14),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          if (suffixWidget != null) suffixWidget,
        ],
      ),
    );
  }
}

// WIDGETS AUXILIARES
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
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
              fontFamily: 'Poppins',
              color: color,
            ),
            maxLines: 1, // ✨ Responsive fix: Asegura que el valor no desborde horizontalmente
            overflow: TextOverflow.ellipsis, // ✨ Responsive fix
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              color: Colors.grey[700],
            ),
            maxLines: 2, // ✨ Responsive fix: Permite que la etiqueta se envuelva, limitando a dos líneas
            overflow: TextOverflow.ellipsis, // ✨ Responsive fix
          ),
        ],
      ),
    );
  }
}

class _CalendarLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _CalendarLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Flexible( // ✨ Responsive fix: Envuelve el texto para que pueda ser limitado
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
            ),
            maxLines: 1, // ✨ Responsive fix
            overflow: TextOverflow.ellipsis, // ✨ Responsive fix
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _SessionCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              DateFormat('HH:mm').format(appointment.scheduledDateTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              maxLines: 1, // ✨ Responsive fix
              overflow: TextOverflow.ellipsis, // ✨ Responsive fix
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 20,
              backgroundImage: appointment.patientProfileUrl != null
                  ? NetworkImage(appointment.patientProfileUrl!)
                  : null,
              backgroundColor: AppConstants.lightAccentColor.withOpacity(0.5),
              child: appointment.patientProfileUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
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
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    appointment.type.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${appointment.durationMinutes} min',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.secondaryColor,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1, // ✨ Responsive fix
                overflow: TextOverflow.ellipsis, // ✨ Responsive fix
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteSessionCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _NoteSessionCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: appointment.patientProfileUrl != null
                      ? NetworkImage(appointment.patientProfileUrl!)
                      : null,
                  backgroundColor: AppConstants.lightAccentColor.withOpacity(0.5),
                  child: appointment.patientProfileUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        appointment.type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(appointment.scheduledDateTime),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1, // ✨ Responsive fix: Asegura que la fecha no desborde
                  overflow: TextOverflow.ellipsis, // ✨ Responsive fix
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              appointment.psychologistNotes ??
                  '${appointment.patientName} completó la sesión de ${appointment.type.displayName}.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ScheduleToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Flexible( // ✨ Responsive fix: Usa Flexible para que el botón pueda encogerse en una Row
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.secondaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppConstants.secondaryColor : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            maxLines: 1, // ✨ Responsive fix
            overflow: TextOverflow.ellipsis, // ✨ Responsive fix
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ArticleCard({
    required this.article,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 220, // ❌ ELIMINADO para permitir que la tarjeta se adapte a su contenedor padre (ej. Expanded o GridView)
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                article.imageUrl != null
                    ? Image.network(
                        article.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.article,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          color: AppConstants.secondaryColor,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: onEdit,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          color: Colors.red,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: onDelete,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: article.isPublished ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      article.isPublished ? 'Publicado' : 'Borrador',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (article.summary != null)
                      Text(
                        article.summary!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible( // ✨ Responsive fix
                          child: Text(
                            '${article.views}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible( // ✨ Responsive fix
                          child: Text(
                            '${article.likes}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (article.createdAt != null)
                      Flexible( // ✨ Responsive fix
                        child: Text(
                          DateFormat('dd MMM yyyy').format(article.createdAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}