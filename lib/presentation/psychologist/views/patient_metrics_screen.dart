// lib/presentation/psychologist/views/patient_metrics_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/data/models/patient_management_model.dart';

class PatientMetricsScreen extends StatelessWidget {
  final List<PatientManagementModel> patients;
  final PatientStatus? focusedStatus;

  const PatientMetricsScreen({
    super.key,
    required this.patients,
    this.focusedStatus,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: ResponsiveText(
          'Métricas de Pacientes',
          baseFontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: ResponsiveUtils.getIconSize(context, 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(context),
            ResponsiveSpacing(20),
            _buildStatusMetrics(context),
            ResponsiveSpacing(20),
            _buildActivityMetrics(context),
            ResponsiveSpacing(20),
            _buildTrendsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final totalPatients = patients.length;
    final activePatients = patients.where((p) => 
        p.status == PatientStatus.inTreatment || 
        p.status == PatientStatus.accepted
    ).length;
    final averageSessions = patients.isNotEmpty 
        ? patients.map((p) => p.totalSessions ?? 0).reduce((a, b) => a + b) / patients.length
        : 0.0;

    final borderRadius = ResponsiveUtils.getBorderRadius(context, 16);
    final cardPadding = ResponsiveUtils.getCardPadding(context);
    final iconSize = ResponsiveUtils.getIconSize(context, 28);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: Container(
        padding: cardPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            colors: [
              AppConstants.primaryColor.withOpacity(0.1),
              AppConstants.lightAccentColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: AppConstants.primaryColor,
                  size: iconSize,
                ),
                ResponsiveHorizontalSpacing(12),
                Expanded(
                  child: ResponsiveText(
                    'Resumen General',
                    baseFontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(20),
            ResponsiveUtils.isMobileSmall(context)
                ? Column(
                    children: [
                      _buildOverviewItem(
                        context, 'Total Pacientes', totalPatients.toString(),
                        Icons.people, AppConstants.primaryColor,
                      ),
                      ResponsiveSpacing(16),
                      _buildOverviewItem(
                        context, 'Activos', activePatients.toString(),
                        Icons.trending_up, Colors.green,
                      ),
                      ResponsiveSpacing(16),
                      _buildOverviewItem(
                        context, 'Prom. Sesiones', averageSessions.toStringAsFixed(1),
                        Icons.analytics, Colors.blue,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildOverviewItem(
                          context, 'Total Pacientes', totalPatients.toString(),
                          Icons.people, AppConstants.primaryColor,
                        ),
                      ),
                      Expanded(
                        child: _buildOverviewItem(
                          context, 'Activos', activePatients.toString(),
                          Icons.trending_up, Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildOverviewItem(
                          context, 'Prom. Sesiones', averageSessions.toStringAsFixed(1),
                          Icons.analytics, Colors.blue,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(
            ResponsiveUtils.getHorizontalSpacing(context, 12),
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveUtils.getIconSize(context, 24),
          ),
        ),
        ResponsiveSpacing(8),
        ResponsiveText(
          value,
          baseFontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        ResponsiveText(
          label,
          baseFontSize: 12,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusMetrics(BuildContext context) {
    final borderRadius = ResponsiveUtils.getBorderRadius(context, 16);
    final cardPadding = ResponsiveUtils.getCardPadding(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Distribución por Estado',
              baseFontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            ResponsiveSpacing(16),
            ...PatientStatus.values.map((status) => 
              _buildStatusMetricItem(context, status)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetricItem(BuildContext context, PatientStatus status) {
    final count = patients.where((p) => p.status == status).length;
    final percentage = patients.isNotEmpty ? (count / patients.length) * 100 : 0.0;
    final color = _getStatusColor(status);
    final isFocused = focusedStatus == status;
    final borderRadius = ResponsiveUtils.getBorderRadius(context, 12);

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getVerticalSpacing(context, 12),
      ),
      padding: EdgeInsets.all(
        ResponsiveUtils.getHorizontalPadding(context),
      ),
      decoration: BoxDecoration(
        color: isFocused ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isFocused ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          ResponsiveHorizontalSpacing(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  status.displayName,
                  baseFontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                ResponsiveText(
                  '$count pacientes (${percentage.toStringAsFixed(1)}%)',
                  baseFontSize: 12,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          ResponsiveText(
            count.toString(),
            baseFontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMetrics(BuildContext context) {
    final patientsWithUpcomingAppointments = patients.where((p) => 
        p.nextAppointment != null && 
        p.nextAppointment!.isAfter(DateTime.now())
    ).length;

    final totalSessions = patients.fold<int>(0, (sum, patient) => 
        sum + (patient.totalSessions ?? 0));

    final patientsWithEmail = patients.where((p) => 
        p.email != null && p.email!.isNotEmpty).length;

    final borderRadius = ResponsiveUtils.getBorderRadius(context, 16);
    final cardPadding = ResponsiveUtils.getCardPadding(context);
    final isMobileSmall = ResponsiveUtils.isMobileSmall(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Métricas de Actividad',
              baseFontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            ResponsiveSpacing(16),
            if (isMobileSmall)
              Column(
                children: [
                  _buildActivityItem(context, 'Citas Próximas',
                    patientsWithUpcomingAppointments.toString(), Icons.schedule, Colors.orange),
                  ResponsiveSpacing(16),
                  _buildActivityItem(context, 'Total Sesiones',
                    totalSessions.toString(), Icons.event_note, Colors.purple),
                  ResponsiveSpacing(16),
                  _buildActivityItem(context, 'Con Email',
                    patientsWithEmail.toString(), Icons.email, Colors.teal),
                  ResponsiveSpacing(16),
                  _buildActivityItem(context, 'Completados',
                    patients.where((p) => p.status == PatientStatus.completed).length.toString(),
                    Icons.check_circle, Colors.green),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildActivityItem(context, 'Citas Próximas',
                        patientsWithUpcomingAppointments.toString(), Icons.schedule, Colors.orange)),
                      ResponsiveHorizontalSpacing(8),
                      Expanded(child: _buildActivityItem(context, 'Total Sesiones',
                        totalSessions.toString(), Icons.event_note, Colors.purple)),
                    ],
                  ),
                  ResponsiveSpacing(16),
                  Row(
                    children: [
                      Expanded(child: _buildActivityItem(context, 'Con Email',
                        patientsWithEmail.toString(), Icons.email, Colors.teal)),
                      ResponsiveHorizontalSpacing(8),
                      Expanded(child: _buildActivityItem(context, 'Completados',
                        patients.where((p) => p.status == PatientStatus.completed).length.toString(),
                        Icons.check_circle, Colors.green)),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final borderRadius = ResponsiveUtils.getBorderRadius(context, 12);
    
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.getHorizontalPadding(context),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.getIconSize(context, 32),
          ),
          ResponsiveSpacing(8),
          ResponsiveText(
            value,
            baseFontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          ResponsiveText(
            label,
            baseFontSize: 12,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(BuildContext context) {
    final borderRadius = ResponsiveUtils.getBorderRadius(context, 16);
    final cardPadding = ResponsiveUtils.getCardPadding(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Insights y Recomendaciones',
              baseFontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            ResponsiveSpacing(16),
            ..._generateInsights(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateInsights(BuildContext context) {
    List<Widget> insights = [];
    
    final pendingCount = patients.where((p) => p.status == PatientStatus.pending).length;
    final inTreatmentCount = patients.where((p) => p.status == PatientStatus.inTreatment).length;
    final completedCount = patients.where((p) => p.status == PatientStatus.completed).length;

    if (pendingCount > 0) {
      insights.add(_buildInsightItem(
        context, 'Pacientes Pendientes',
        'Tienes $pendingCount pacientes esperando aceptación. Considera revisarlos pronto.',
        Icons.pending_actions, Colors.orange,
      ));
    }

    if (inTreatmentCount > completedCount * 2) {
      insights.add(_buildInsightItem(
        context, 'Alta Carga de Trabajo',
        'Tienes muchos pacientes en tratamiento activo. Considera optimizar tu agenda.',
        Icons.trending_up, Colors.blue,
      ));
    }

    if (completedCount > 0) {
      insights.add(_buildInsightItem(
        context, 'Excelente Trabajo',
        'Has completado el tratamiento de $completedCount pacientes. ¡Felicitaciones!',
        Icons.celebration, Colors.green,
      ));
    }

    if (insights.isEmpty) {
      insights.add(_buildInsightItem(
        context, 'Todo bajo Control',
        'Tus métricas se ven bien. Mantén el buen trabajo.',
        Icons.thumb_up, AppConstants.primaryColor,
      ));
    }

    return insights;
  }

  Widget _buildInsightItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final borderRadius = ResponsiveUtils.getBorderRadius(context, 12);
    
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getVerticalSpacing(context, 12),
      ),
      padding: EdgeInsets.all(
        ResponsiveUtils.getHorizontalPadding(context),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.getIconSize(context, 24),
          ),
          ResponsiveHorizontalSpacing(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  title,
                  baseFontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                ResponsiveSpacing(4),
                ResponsiveText(
                  description,
                  baseFontSize: 12,
                ),
              ],
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
}