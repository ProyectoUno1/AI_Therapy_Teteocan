import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    required this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Sin título',
      body: map['body'] ?? 'Sin cuerpo',
      type: map['type'] ?? 'general',
      timestamp: _parseTimestamp(map['timestamp']),
      isRead: map['isRead'] ?? false,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  // Función helper para parsear diferentes formatos de timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    
    try {
      if (timestamp is String) {
        // Primero intentar parsear como ISO string
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          // Si falla, intentar parsear el formato español
          return _parseSpanishDateTime(timestamp);
        }
      } else if (timestamp is Timestamp) {
        // Si es un Firestore Timestamp
        return timestamp.toDate();
      } else if (timestamp is int) {
        // Si es timestamp en milisegundos
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is Map<String, dynamic>) {
        // Si es un objeto Timestamp de Firestore
        if (timestamp['_seconds'] != null) {
          final seconds = timestamp['_seconds'] as int;
          final nanoseconds = timestamp['_nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        }
      }
      
      // Si no se pudo parsear, usar fecha actual
      return DateTime.now();
    } catch (e) {
      // En caso de error, retornar fecha actual
      return DateTime.now();
    }
  }

  // Función para parsear el formato español: "4 de septiembre de 2025, 6:49:36 p.m. UTC-7"
  static DateTime _parseSpanishDateTime(String dateString) {
    try {
      // Limpiar y normalizar el string
      String normalized = dateString.replaceAll('a.m.', 'AM').replaceAll('p.m.', 'PM');
      
      // Extraer partes de la fecha
      final parts = normalized.split(', ');
      if (parts.length != 2) {
        return DateTime.now();
      }
      
      final datePart = parts[0]; // "4 de septiembre de 2025"
      final timePart = parts[1]; // "6:49:36 PM UTC-7"
      
      // Parsear la parte de la fecha
      final dateRegex = RegExp(r'(\d+) de (\w+) de (\d+)');
      final dateMatch = dateRegex.firstMatch(datePart);
      if (dateMatch == null) {
        return DateTime.now();
      }
      
      final day = int.parse(dateMatch.group(1)!);
      final monthName = dateMatch.group(2)!;
      final year = int.parse(dateMatch.group(3)!);
      
      // Mapear nombres de meses en español a números
      final monthMap = {
        'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
        'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
        'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12
      };
      
      final month = monthMap[monthName.toLowerCase()];
      if (month == null) {
        return DateTime.now();
      }
      
      // Parsear la parte de la hora
      final timeRegex = RegExp(r'(\d+):(\d+):(\d+) ([AP]M) UTC([+-]\d+)');
      final timeMatch = timeRegex.firstMatch(timePart);
      if (timeMatch == null) {
        return DateTime.now();
      }
      
      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      final second = int.parse(timeMatch.group(3)!);
      final period = timeMatch.group(4)!;
      final timezoneOffset = timeMatch.group(5)!;
      
      // Convertir a formato 24 horas
      if (period == 'PM' && hour < 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      
      return DateTime(year, month, day, hour, minute, second);
      
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  List<Object> get props => [id, title, body, type, timestamp, isRead, data];
}