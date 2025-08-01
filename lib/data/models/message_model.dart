// lib/data/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MessageModel {
  final String id;
  final String content;
  final bool isUser;
  final DateTime? timestamp;

  MessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    this.timestamp,
  });
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      content: json['text'] as String,
      isUser:
          json['isUser'] as bool? ??
          false, // isUser es TRUE para mensajes del usuario, FALSE para IA
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content, // <--- And here
      'isUser': isUser,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}
