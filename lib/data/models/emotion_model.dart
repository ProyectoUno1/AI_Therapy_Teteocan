// lib/data/models/emotion_model.dart
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';

class Emotion {
  final String? id;
  final String patientId;
  final Feeling feeling;
  final String? note;
  final DateTime date;
  final int? intensity;
  final Map<String, dynamic>? metadata;

  Emotion({
    this.id,
    required this.patientId,
    required this.feeling,
    this.note,
    required this.date,
    this.intensity,
    this.metadata,
  });

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion.fromMap(json);
  }

  factory Emotion.fromMap(Map<String, dynamic> map) {
    return Emotion(
      id: map['id'],
      patientId: map['patientId'],
      feeling: _stringToFeeling(map['feeling']),
      note: map['note'],
      date: DateTime.parse(map['date']),
      intensity: map['intensity'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'feeling': _feelingToString(feeling),
      'note': note,
      'date': date.toIso8601String(),
      'intensity': intensity,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  static Feeling _stringToFeeling(String feeling) {
    switch (feeling.toLowerCase()) {
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
      case 'happy':
        return Feeling.great;
      case 'sad':
        return Feeling.bad;
      case 'angry':
        return Feeling.bad;
      case 'anxious':
        return Feeling.bad;
      case 'calm':
        return Feeling.good;
      case 'excited':
        return Feeling.great;
      default:
        return Feeling.neutral;
    }
  }

  static String _feelingToString(Feeling feeling) {
    return feeling.toString().split('.').last;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Emotion &&
        other.id == id &&
        other.patientId == patientId &&
        other.feeling == feeling &&
        other.date == date;
  }

  @override
  int get hashCode => id.hashCode ^ patientId.hashCode ^ feeling.hashCode ^ date.hashCode;
}