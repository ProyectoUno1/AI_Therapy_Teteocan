// lib/data/models/patient_note.dart

import 'package:equatable/equatable.dart';

class PatientNote extends Equatable {
  final String id;
  final String patientId;
  final String psychologistId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientNote({
    required this.id,
    required this.patientId,
    required this.psychologistId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        psychologistId,
        title,
        content,
        createdAt,
        updatedAt,
      ];

  factory PatientNote.fromJson(Map<String, dynamic> json) {
    return PatientNote(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      psychologistId: json['psychologistId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'psychologistId': psychologistId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PatientNote copyWith({
    String? id,
    String? patientId,
    String? psychologistId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientNote(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      psychologistId: psychologistId ?? this.psychologistId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}