//lib/presentation/shared/notification_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_event.dart';
import 'package:ai_therapy_teteocan/data/models/notification_model.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/chat_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_chat_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_bloc.dart';
import 'dart:developer';

class NotificationsPanelScreen extends StatelessWidget {
  final VoidCallback? onNavigateToChat;
  const NotificationsPanelScreen({super.key, this.onNavigateToChat});

  String formatDate(dynamic timestamp) {
    if (timestamp == null) {
      return 'Fecha no disponible';
    }

    try {
      DateTime dateTime;

      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is String) {
        try {
          dateTime = DateTime.parse(timestamp);
        } catch (e) {
          dateTime = _parseSpanishDateTime(timestamp);
        }
      } else if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is double) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      } else if (timestamp is Map<String, dynamic> &&
          timestamp['_seconds'] != null) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(
          timestamp['_seconds'] * 1000,
        );
      } else {
        return 'Formato desconocido';
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final notificationDate = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      );

      if (notificationDate.isAtSameMomentAs(today)) {
        return 'Hoy, ${DateFormat('HH:mm').format(dateTime)}';
      } else if (notificationDate.isAtSameMomentAs(yesterday)) {
        return 'Ayer, ${DateFormat('HH:mm').format(dateTime)}';
      } else {
        return '${DateFormat('dd/MM/yyyy').format(dateTime)} a las ${DateFormat('HH:mm').format(dateTime)}';
      }
    } catch (e) {
      log(
        'Error al parsear timestamp: $e. Valor: $timestamp',
        name: 'NotifPanel',
      );
      return 'Fecha inválida';
    }
  }

  DateTime _parseSpanishDateTime(String dateString) {
    try {
      String normalized = dateString
          .replaceAll('a.m.', 'AM')
          .replaceAll('p.m.', 'PM');
      final parts = normalized.split(', ');
      if (parts.length != 2) return DateTime.now();

      final datePart = parts[0];
      final timePart = parts[1];

      final dateRegex = RegExp(r'(\d+) de (\w+) de (\d+)');
      final dateMatch = dateRegex.firstMatch(datePart);
      if (dateMatch == null) return DateTime.now();

      final day = int.parse(dateMatch.group(1)!);
      final monthName = dateMatch.group(2)!;
      final year = int.parse(dateMatch.group(3)!);

      final monthMap = {
        'enero': 1,
        'febrero': 2,
        'marzo': 3,
        'abril': 4,
        'mayo': 5,
        'juno': 6,
        'julio': 7,
        'agosto': 8,
        'septiembre': 9,
        'octubre': 10,
        'noviembre': 11,
        'diciembre': 12,
      };

      final month = monthMap[monthName.toLowerCase()];
      if (month == null) return DateTime.now();

      final timeRegex = RegExp(r'(\d+):(\d+):(\d+) ([AP]M) UTC([+-]\d+)');
      final timeMatch = timeRegex.firstMatch(timePart);
      if (timeMatch == null) return DateTime.now();

      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      final second = int.parse(timeMatch.group(3)!);
      final period = timeMatch.group(4)!;

      if (period == 'PM' && hour < 12)
        hour += 12;
      else if (period == 'AM' && hour == 12)
        hour = 0;

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final authState = context.read<AuthBloc>().state;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final userToken = await user.getIdToken();
    final userId = user.uid;

    context.read<NotificationBloc>().add(
      MarkNotificationAsRead(
        notificationId: notification.id,
        userId: userId,
        userToken: userToken!,
        userType: authState.isAuthenticatedPatient ? 'patient' : 'psychologist',
      ),
    );

    bool shouldNavigateToAppointments = false;
    final lowerCaseType = notification.type.toLowerCase();

    if (lowerCaseType == 'cita' || lowerCaseType == 'appointment') {
      shouldNavigateToAppointments = true;
    } else if (notification.title.toLowerCase().contains('cita') ||
        notification.title.toLowerCase().contains('appointment')) {
      shouldNavigateToAppointments = true;
    }

    if (shouldNavigateToAppointments) {
      final appointmentId = notification.data['appointmentId'] as String?;
      final status = notification.data['status'] as String?;

      if (authState.isAuthenticatedPsychologist) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AppointmentsListScreen(psychologistId: userId),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PatientAppointmentsListScreen(
              highlightAppointmentId: appointmentId,
              filterStatus: status,
            ),
          ),
        );
      }
    } else {
      switch (lowerCaseType) {
        case 'chat':
        case 'chat_message':
          if (authState.isAuthenticatedPsychologist) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => PsychologistHomeScreen(
                  initialTabIndex: 1, 
                ),
              ),
              (route) => false,
            );
          } else if (authState.isAuthenticatedPatient) {
            final psychologistId =
                notification.data['psychologistId'] as String?;
            final chatId = notification.data['chatId'] as String?;

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PatientHomeScreen(
                  initialChatPsychologistId: psychologistId,
                  initialChatId: chatId,
                ),
              ),
            );
          }
          break;
        default:
          // Para otros tipos de notificación, simplemente cerrar el panel
          Navigator.of(context).pop();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.primary),
            onPressed: () async {
              final authState = context.read<AuthBloc>().state;
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userToken = await user.getIdToken();
                if (userToken != null) {
                  context.read<NotificationBloc>().add(
                    DeleteReadNotifications(
                      userToken: userToken,
                      userId: user.uid,
                      userType: authState.isAuthenticatedPatient
                          ? 'patient'
                          : 'psychologist',
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Text(
                  'No tienes notificaciones.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: NotificationItem(
                    notification: notification,
                    onTap: () => _handleNotificationTap(context, notification),
                    isDarkMode: isDarkMode,
                    formatDate: formatDate,
                  ),
                );
              },
            );
          } else if (state is NotificationError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final bool isDarkMode;
  final String Function(dynamic) formatDate;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.isDarkMode,
    required this.formatDate,
  });

  IconData _getNotificationIcon(NotificationModel notification) {
    final lowerCaseType = notification.type.toLowerCase();
    final lowerCaseTitle = notification.title.toLowerCase();
    final lowerCaseBody = notification.body.toLowerCase();

    // Priorizar por tipo específico
    switch (lowerCaseType) {
      case 'cita':
      case 'appointment':
      case 'recordatorio_cita':
        return Icons.calendar_today;

      case 'ejercicio':
      case 'exercise':
      case 'actividad':
        return Icons.fitness_center;

      case 'motivacion':
      case 'motivacional':
      case 'frase_motivadora':
        return Icons.emoji_objects;

      case 'chat':
      case 'chat_message':
      case 'mensaje':
        return Icons.chat_bubble_outline;

      case 'bienvenida':
      case 'welcome':
        return Icons.waving_hand_outlined;

      case 'alerta':
      case 'alert':
      case 'importante':
        return Icons.warning_amber_rounded;

      case 'recordatorio':
      case 'reminder':
        return Icons.notifications_active;
    }

    // Buscar en el título
    if (lowerCaseTitle.contains('cita') ||
        lowerCaseTitle.contains('appointment') ||
        lowerCaseTitle.contains('consulta')) {
      return Icons.calendar_today;
    } else if (lowerCaseTitle.contains('ejercicio') ||
        lowerCaseTitle.contains('exercise') ||
        lowerCaseTitle.contains('actividad')) {
      return Icons.fitness_center;
    } else if (lowerCaseTitle.contains('motivacion') ||
        lowerCaseTitle.contains('motivacional') ||
        lowerCaseTitle.contains('frase')) {
      return Icons.emoji_objects;
    } else if (lowerCaseTitle.contains('chat') ||
        lowerCaseTitle.contains('mensaje')) {
      return Icons.chat_bubble_outline;
    } else if (lowerCaseTitle.contains('recordatorio')) {
      return Icons.notifications_active;
    }

    // Buscar en el cuerpo
    if (lowerCaseBody.contains('cita') ||
        lowerCaseBody.contains('appointment') ||
        lowerCaseBody.contains('consulta')) {
      return Icons.calendar_today;
    } else if (lowerCaseBody.contains('ejercicio') ||
        lowerCaseBody.contains('exercise') ||
        lowerCaseBody.contains('actividad')) {
      return Icons.fitness_center;
    } else if (lowerCaseBody.contains('motivacion') ||
        lowerCaseBody.contains('motivacional') ||
        lowerCaseBody.contains('frase')) {
      return Icons.emoji_objects;
    } else if (lowerCaseBody.contains('chat') ||
        lowerCaseBody.contains('mensaje')) {
      return Icons.chat_bubble_outline;
    } else if (lowerCaseBody.contains('recordatorio')) {
      return Icons.notifications_active;
    }

    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final formattedDate = formatDate(notification.timestamp);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDarkMode ? Colors.grey[850] : Colors.grey[100])
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? (isDarkMode ? Colors.grey[700] : Colors.grey[200])
                      : theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: notification.isRead
                      ? (isDarkMode ? Colors.grey[500] : Colors.grey[600])
                      : theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: notification.isRead
                            ? Colors.grey
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: notification.isRead
                              ? (isDarkMode ? Colors.grey[500] : Colors.grey)
                              : theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: notification.isRead
                                ? (isDarkMode ? Colors.grey[500] : Colors.grey)
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.secondary.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
