// lib/data/repositories/notification_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_therapy_teteocan/data/models/notification_model.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';

class NotificationRepository {
  final String _apiBaseUrl = '${ApiConstants.baseUrl}/api';

  NotificationRepository();

 
  Future<List<NotificationModel>> fetchNotificationsForUser(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((json) => NotificationModel.fromMap(json, json['id']))
          .toList();
    } else {
      throw Exception(
        'Error al obtener notificaciones: ${response.statusCode}',
      );
    }
  } catch (e) {
    throw Exception('Error de conexión al servidor: $e');
  }
}

  Future<void> markNotificationAsRead(String token, dynamic notificationId) async {
  try {
   
    final response = await http.patch(
      Uri.parse('$_apiBaseUrl/notifications/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al marcar notificación como leída: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de conexión al servidor: $e');
  }
}

  

  Future<void> deleteNotification(String token, String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Error al eliminar notificación: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión al servidor: $e');
    }
  }

  Future<void> deleteReadNotifications(String token) async {
  try {
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/notifications/clear-read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Error al eliminar notificaciones leídas: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Error de conexión al servidor: $e');
  }
}


}
