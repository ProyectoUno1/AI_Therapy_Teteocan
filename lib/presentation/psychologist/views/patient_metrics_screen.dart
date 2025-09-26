// lib/presentation/psychologist/views/patient_metrics_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Métricas de Pacientes',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen General
            _buildOverviewCard(context),
            const SizedBox(height: 20),

            // Métricas por Estado
            _buildStatusMetrics(context),
            const SizedBox(height: 20),

            // Métricas de Actividad
            _buildActivityMetrics(context),
            const SizedBox(height: 20),

            // Tendencias
            _buildTrendsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final totalPatients = patients.length;
    final activePatients = patients
        .where(
          (p) =>
              p.status == PatientStatus.inTreatment ||
              p.status == PatientStatus.accepted,
        )
        .length;
    final averageSessions = patients.isNotEmpty
        ? patients.map((p) => p.totalSessions ?? 0).reduce((a, b) => a + b) /
              patients.length
        : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resumen General',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    context,
                    'Total Pacientes',
                    totalPatients.toString(),
                    Icons.people,
                    AppConstants.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    context,
                    'Activos',
                    activePatients.toString(),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    context,
                    'Prom. Sesiones',
                    averageSessions.toStringAsFixed(1),
                    Icons.analytics,
                    Colors.blue,
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
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'Poppins'),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusMetrics(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución por Estado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ...PatientStatus.values
                .map((status) => _buildStatusMetricItem(context, status))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetricItem(BuildContext context, PatientStatus status) {
    final count = patients.where((p) => p.status == status).length;
    final percentage = patients.isNotEmpty
        ? (count / patients.length) * 100
        : 0.0;
    final color = _getStatusColor(status);
    final isFocused = focusedStatus == status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFocused ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isFocused ? Border.all(color: color, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '$count pacientes (${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMetrics(BuildContext context) {
    final patientsWithUpcomingAppointments = patients
        .where(
          (p) =>
              p.nextAppointment != null &&
              p.nextAppointment!.isAfter(DateTime.now()),
        )
        .length;

    final totalSessions = patients.fold<int>(
      0,
      (sum, patient) => sum + (patient.totalSessions ?? 0),
    );

    final patientsWithEmail = patients
        .where((p) => p.email != null && p.email!.isNotEmpty)
        .length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas de Actividad',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActivityItem(
                    context,
                    'Citas Próximas',
                    patientsWithUpcomingAppointments.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildActivityItem(
                    context,
                    'Total Sesiones',
                    totalSessions.toString(),
                    Icons.event_note,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActivityItem(
                    context,
                    'Con Email',
                    patientsWithEmail.toString(),
                    Icons.email,
                    Colors.teal,
                  ),
                ),
                Expanded(
                  child: _buildActivityItem(
                    context,
                    'Completados',
                    patients
                        .where((p) => p.status == PatientStatus.completed)
                        .length
                        .toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'Poppins'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights y Recomendaciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ..._generateInsights(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateInsights(BuildContext context) {
    List<Widget> insights = [];

    final pendingCount = patients
        .where((p) => p.status == PatientStatus.pending)
        .length;
    final inTreatmentCount = patients
        .where((p) => p.status == PatientStatus.inTreatment)
        .length;
    final completedCount = patients
        .where((p) => p.status == PatientStatus.completed)
        .length;

    if (pendingCount > 0) {
      insights.add(
        _buildInsightItem(
          context,
          'Pacientes Pendientes',
          'Tienes $pendingCount pacientes esperando aceptación. Considera revisarlos pronto.',
          Icons.pending_actions,
          Colors.orange,
        ),
      );
    }

    if (inTreatmentCount > completedCount * 2) {
      insights.add(
        _buildInsightItem(
          context,
          'Alta Carga de Trabajo',
          'Tienes muchos pacientes en tratamiento activo. Considera optimizar tu agenda.',
          Icons.trending_up,
          Colors.blue,
        ),
      );
    }

    if (completedCount > 0) {
      insights.add(
        _buildInsightItem(
          context,
          'Excelente Trabajo',
          'Has completado el tratamiento de $completedCount pacientes. ¡Felicitaciones!',
          Icons.celebration,
          Colors.green,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        _buildInsightItem(
          context,
          'Todo bajo Control',
          'Tus métricas se ven bien. Mantén el buen trabajo.',
          Icons.thumb_up,
          AppConstants.primaryColor,
        ),
      );
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'Poppins'),
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
