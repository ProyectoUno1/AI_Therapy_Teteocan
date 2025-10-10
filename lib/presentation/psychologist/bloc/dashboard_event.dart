// lib/presentation/psychologist/bloc/dashboard_event.dart

abstract class DashboardEvent {
  const DashboardEvent();
}

class LoadDashboardData extends DashboardEvent {
  final String psychologistId;
  const LoadDashboardData(this.psychologistId);
}

class RefreshDashboard extends DashboardEvent {
  final String psychologistId;
  const RefreshDashboard(this.psychologistId);
}