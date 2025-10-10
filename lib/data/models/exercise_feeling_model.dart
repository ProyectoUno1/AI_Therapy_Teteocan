// lib/data/models/exercise_feeling_model.dart

import 'package:equatable/equatable.dart';

class ExerciseFeelingModel extends Equatable {
  final String id;
  final String patientId;
  final String exerciseTitle;
  final int exerciseDuration;
  final String exerciseDifficulty;
  final String feeling;
  final int intensity;
  final String notes;
  final DateTime completedAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ExerciseFeelingModel({
    required this.id,
    required this.patientId,
    required this.exerciseTitle,
    required this.exerciseDuration,
    required this.exerciseDifficulty,
    required this.feeling,
    required this.intensity,
    required this.notes,
    required this.completedAt,
    this.metadata,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        exerciseTitle,
        exerciseDuration,
        exerciseDifficulty,
        feeling,
        intensity,
        notes,
        completedAt,
        metadata,
        createdAt,
      ];

  factory ExerciseFeelingModel.fromJson(Map<String, dynamic> json) {
    return ExerciseFeelingModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      exerciseTitle: json['exerciseTitle'] as String,
      exerciseDuration: json['exerciseDuration'] as int,
      exerciseDifficulty: json['exerciseDifficulty'] as String,
      feeling: json['feeling'] as String,
      intensity: json['intensity'] as int,
      notes: json['notes'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'exerciseTitle': exerciseTitle,
      'exerciseDuration': exerciseDuration,
      'exerciseDifficulty': exerciseDifficulty,
      'feeling': feeling,
      'intensity': intensity,
      'notes': notes,
      'completedAt': completedAt.toIso8601String(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}