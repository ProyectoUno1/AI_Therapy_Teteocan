// lib/data/models/emotion_model.dart

import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';

class Emotion {
  final String id;
  final String patientId;
  final Feeling feeling;
  final DateTime date;
  final int intensity;
  final String? note;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Emotion({
    this.id = '',
    required this.patientId,
    required this.feeling,
    required this.date,
    this.intensity = 5,
    this.note,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Método para convertir a Map (enviar al backend)
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'patientId': patientId,
      'feeling': feeling.toString().split('.').last,
      'date': date.toIso8601String(),
      'intensity': intensity,
      'note': note,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ✅ Alias para compatibilidad (toJson = toMap)
  Map<String, dynamic> toJson() => toMap();

  // Método para crear desde Map (recibir del backend)
  factory Emotion.fromMap(Map<String, dynamic> map) {
    return Emotion(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      feeling: _feelingFromString(map['feeling']),
      date: _parseDate(map['date']),
      intensity: map['intensity'] ?? 5,
      note: map['note'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  // ✅ Alias para compatibilidad (fromJson = fromMap)
  factory Emotion.fromJson(Map<String, dynamic> json) => Emotion.fromMap(json);

  // Helper para parsear fechas de forma segura
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Helper para convertir string a Feeling
  static Feeling _feelingFromString(dynamic feeling) {
    if (feeling == null) return Feeling.neutral;
    
    final feelingStr = feeling.toString().toLowerCase();
    switch (feelingStr) {
      case 'terrible':
        return Feeling.terrible;
      case 'bad':
        return Feeling.bad;
      case 'neutral':
        return Feeling.neutral;
      case 'good':
        return Feeling.good;
      case 'great':
        return Feeling.great;
      default:
        return Feeling.neutral;
    }
  }

  // Método copyWith para crear copias con modificaciones
  Emotion copyWith({
    String? id,
    String? patientId,
    Feeling? feeling,
    DateTime? date,
    int? intensity,
    String? note,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Emotion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      feeling: feeling ?? this.feeling,
      date: date ?? this.date,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Emotion(id: $id, patientId: $patientId, feeling: $feeling, date: $date, intensity: $intensity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Emotion &&
      other.id == id &&
      other.patientId == patientId &&
      other.feeling == feeling &&
      other.date == date &&
      other.intensity == intensity &&
      other.note == note;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      patientId.hashCode ^
      feeling.hashCode ^
      date.hashCode ^
      intensity.hashCode ^
      note.hashCode;
  }
}