// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Callback para manejar navegación
  static Function(Map<String, dynamic>)? onNotificationTap;

  static Future<void> initialize() async {
    await _requestPermissions();
    await _setupFCM();
    _setupMessageHandlers();
  }

  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );
  }

  static Future<void> _setupFCM() async {
    // Obtener token FCM
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToBackend(token);
      print('FCM Token: $token');
    }

    // Manejar actualizaciones de token
    _messaging.onTokenRefresh.listen(_saveTokenToBackend);
  }

  static Future<void> _saveTokenToBackend(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final idToken = await user.getIdToken();
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/fcm-token'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'fcmToken': token}),
      );
    } catch (e) {
      print('Error guardando token FCM: $e');
    }
  }

  static void _setupMessageHandlers() {
    // App en primer plano - mostrar notificación in-app personalizada
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showInAppNotification(message);
    });

    // App en background/terminated - usuario hace tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });

    // App completamente cerrada - verificar mensaje inicial
    _checkInitialMessage();
  }

  static Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data);
    }
  }

  // Mostrar notificación personalizada dentro de la app
  static void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    if (onInAppNotification != null) {
      onInAppNotification!({
        'title': notification.title ?? '',
        'body': notification.body ?? '',
        'data': message.data,
        'type': message.data['type'] ?? 'general',
      });
    }
  }

  // Callback para notificaciones in-app
  static Function(Map<String, dynamic>)? onInAppNotification;

  static void _handleNotificationClick(Map<String, dynamic> data) {
    if (onNotificationTap != null) {
      onNotificationTap!(data);
    } else {
      print('No hay handler configurado para notificaciones');
    }
  }

  // Obtener token FCM guardado localmente
  static Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      return null;
    }
  }

  // Obtener token FCM actual
  static Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  // Suscribirse a un topic
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Desuscribirse de un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

// Clase para manejar navegación desde notificaciones
class NotificationNavigator {
  static void handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'appointment_created':
      case 'appointment_confirmed':
      case 'appointment_cancelled':
        _navigateToAppointments(data);
        break;
        
      case 'subscription_activated':
      case 'payment_succeeded':
      case 'payment_failed':
        _navigateToSubscription(data);
        break;
        
      case 'session_started':
      case 'session_completed':
        _navigateToSession(data);
        break;
        
      case 'session_rated':
        _navigateToRatings(data);
        break;
        
      default:
        _navigateToNotifications();
        break;
    }
  }

  static void _navigateToAppointments(Map<String, dynamic> data) {
    // Implementar navegación a citas
    print('Navegar a citas: $data');
  }

  static void _navigateToSubscription(Map<String, dynamic> data) {
    // Implementar navegación a suscripción
    print('Navegar a suscripción: $data');
  }

  static void _navigateToSession(Map<String, dynamic> data) {
    // Implementar navegación a sesión
    print('Navegar a sesión: $data');
  }

  static void _navigateToRatings(Map<String, dynamic> data) {
    // Implementar navegación a ratings
    print('Navegar a ratings: $data');
  }

  static void _navigateToNotifications() {
    // Implementar navegación a lista de notificaciones
    print('Navegar a notificaciones');
  }
}

// Widget personalizado para mostrar notificaciones in-app
class InAppNotificationWidget extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const InAppNotificationWidget({
    Key? key,
    required this.title,
    required this.body,
    required this.type,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getColorForType(type),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _getIconForType(type),
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'appointment_created':
      case 'appointment_confirmed':
        return const Color(0xFF2196F3);
      case 'subscription_activated':
      case 'payment_succeeded':
        return const Color(0xFF4CAF50);
      case 'session_started':
      case 'session_completed':
        return const Color(0xFF9C27B0);
      case 'payment_failed':
      case 'appointment_cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'appointment_created':
      case 'appointment_confirmed':
        return Icons.calendar_today;
      case 'subscription_activated':
      case 'payment_succeeded':
        return Icons.check_circle;
      case 'session_started':
      case 'session_completed':
        return Icons.psychology;
      case 'payment_failed':
        return Icons.error;
      case 'appointment_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }
}