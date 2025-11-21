/// lib/presentation/shared/notification_panel_screen.dart


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';
import 'package:ai_therapy_teteocan/data/models/notification_model.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/views/subscription_screen.dart';
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
        'junio': 6,
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
    bool shouldNavigateToSubscription = false;
    final lowerCaseType = notification.type.toLowerCase();

    if (lowerCaseType == 'subscription' || 
        lowerCaseType == 'pago' || 
        lowerCaseType == 'payment' ||
        lowerCaseType == 'suscripción' ||
        lowerCaseType == 'premium') {
      shouldNavigateToSubscription = true;
    } else if (notification.title.toLowerCase().contains('suscripción') ||
        notification.title.toLowerCase().contains('subscription') ||
        notification.title.toLowerCase().contains('pago') ||
        notification.title.toLowerCase().contains('payment') ||
        notification.title.toLowerCase().contains('premium')) {
      shouldNavigateToSubscription = true;
    } else if (lowerCaseType == 'cita' || lowerCaseType == 'appointment') {
      shouldNavigateToAppointments = true;
    } else if (notification.title.toLowerCase().contains('cita') ||
        notification.title.toLowerCase().contains('appointment')) {
      shouldNavigateToAppointments = true;
    }
    
    if (shouldNavigateToSubscription) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SubscriptionScreen(),
        ),
      );
    } else if (shouldNavigateToAppointments) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Configuración responsive
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;
    
    final maxContentWidth = isDesktop ? 800.0 : (isTablet ? 700.0 : screenWidth);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        // Añadir una minWidth para el título en caso de pantallas muy estrechas
        title: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Notificaciones',
              style: TextStyle(
                fontSize: isMobile ? 17 : (isTablet ? 19 : 20),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.primary,
            size: isMobile ? 22 : 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8 : 12),
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.primary,
                size: isMobile ? 22 : 24,
              ),
              tooltip: 'Eliminar leídas',
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
          ),
        ],
      ),
      body: SafeArea(
        // 🌟 CLAVE: Envuelve el cuerpo con SingleChildScrollView
        // Esto permite el scroll vertical en el modo de error o vacío,
        // especialmente en orientación horizontal donde la altura es reducida.
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    // Envuelto en un contenedor para darle una altura mínima en caso de scroll
                    return Container(
                      height: mediaQuery.size.height - AppBar().preferredSize.height - mediaQuery.padding.top,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  } else if (state is NotificationLoaded) {
                    if (state.notifications.isEmpty) {
                      return _buildEmptyState(context, isMobile, isTablet);
                    }
                    
                    // Si hay notificaciones, el ListView.builder se encarga del scroll.
                    // Se envuelve en ConstrainedBox/SizedBox para que ocupe todo el alto disponible, 
                    // si el SingleChildScrollView está presente, es mejor permitir que se adapte.
                    return ListView.builder(
                      // 💡 CLAVE: Usar 'shrinkWrap' y 'physics: NeverScrollableScrollPhysics()' 
                      // para que el ListView no intente gestionar su propio scroll y 
                      // se integre con el SingleChildScrollView padre.
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : (isTablet ? 16 : 20),
                        vertical: isMobile ? 8 : 12,
                      ),
                      itemCount: state.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
                          child: NotificationItem(
                            notification: notification,
                            onTap: () => _handleNotificationTap(context, notification),
                            isDarkMode: isDarkMode,
                            formatDate: formatDate,
                            isMobile: isMobile,
                            isTablet: isTablet,
                            isDesktop: isDesktop,
                          ),
                        );
                      },
                    );
                  } else if (state is NotificationError) {
                    return _buildErrorState(context, state.message, isMobile, isTablet);
                  }
                  return Container();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isMobile, bool isTablet) {
    final theme = Theme.of(context);
    final iconSize = isMobile ? 56.0 : (isTablet ? 64.0 : 72.0);
    
    // Asegurar que las vistas de estado (vacío/error) también puedan expandirse
    // si el contenido lo requiere y se usa el SingleChildScrollView.
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : (isTablet ? 32 : 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FractionallySizedBox(
              widthFactor: isMobile ? 0.25 : 0.2,
              child: AspectRatio(
                aspectRatio: 1,
                child: Icon(
                  Icons.notifications_none,
                  size: iconSize,
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            FittedBox(
              child: Text(
                'No tienes notificaciones.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, bool isMobile, bool isTablet) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : (isTablet ? 32 : 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: isMobile ? 56 : 64, color: Colors.red),
            SizedBox(height: isMobile ? 16 : 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Error: $message',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                  fontSize: isMobile ? 14 : 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final token = await user.getIdToken();
                  if (token != null) {
                    final authState = context.read<AuthBloc>().state;
                    context.read<NotificationBloc>().add(
                      LoadNotifications(
                        userId: user.uid,
                        userToken: token,
                        userType: authState.isAuthenticatedPatient
                            ? 'patient'
                            : 'psychologist',
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Reintentar',
                style: TextStyle(fontSize: isMobile ? 14 : 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET NOTIFICATION ITEM RESPONSIVE CON DATOS REALES
class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final bool isDarkMode;
  final String Function(dynamic) formatDate;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.isDarkMode,
    required this.formatDate,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  IconData _getNotificationIcon(NotificationModel notification) {
    final lowerCaseType = notification.type.toLowerCase();
    final lowerCaseTitle = notification.title.toLowerCase();

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
      case 'subscription':
      case 'suscripción':
      case 'pago':
      case 'payment':
      case 'premium':
        return Icons.credit_card;
    }

    if (lowerCaseTitle.contains('cita') ||
        lowerCaseTitle.contains('appointment') ||
        lowerCaseTitle.contains('consulta')) {
      return Icons.calendar_today;
    } else if (lowerCaseTitle.contains('suscripción') ||
        lowerCaseTitle.contains('subscription') ||
        lowerCaseTitle.contains('pago') ||
        lowerCaseTitle.contains('payment') ||
        lowerCaseTitle.contains('premium')) {
      return Icons.credit_card;
    }

    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = formatDate(notification.timestamp);
    final iconSize = isMobile ? 40.0 : (isTablet ? 44.0 : 48.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDarkMode ? Colors.grey[850] : Colors.grey[100])
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 14 : 16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? (isDarkMode ? Colors.grey[700] : Colors.grey[200])
                      : theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: notification.isRead
                      ? (isDarkMode ? Colors.grey[500] : Colors.grey[600])
                      : theme.colorScheme.secondary,
                  size: isMobile ? 20 : (isTablet ? 22 : 24),
                ),
              ),
              
              SizedBox(width: isMobile ? 12 : (isTablet ? 14 : 16)),
              
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: notification.isRead ? Colors.grey : theme.textTheme.bodyMedium?.color,
                        fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: isMobile ? 12 : 14,
                          color: notification.isRead
                              ? (isDarkMode ? Colors.grey[500] : Colors.grey)
                              : theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: notification.isRead
                                  ? (isDarkMode ? Colors.grey[500] : Colors.grey)
                                  : theme.colorScheme.secondary,
                              fontSize: isMobile ? 10 : (isTablet ? 11 : 12),
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Indicador de no leído
              if (!notification.isRead)
                Padding(
                  padding: EdgeInsets.only(left: isMobile ? 8 : 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: isMobile ? 8 : 10,
                    height: isMobile ? 8 : 10,
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