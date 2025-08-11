// lib/data/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Constructor de fábrica para mensajes de la IA (desde una respuesta de API)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      content: json['text'] as String? ?? '', 
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  // Constructor de fábrica para mensajes de Firestore (psicólogos y IA)
  factory MessageModel.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    final senderId = data['senderId'] as String? ?? '';

    final bool isUser = senderId == currentUserId;

    return MessageModel(
      id: doc.id,
      content: data['content'] as String? ?? '', 
      isUser: isUser,
      timestamp: timestamp?.toDate(),
    );
  }

  // Método para enviar mensajes a Firestore
  Map<String, dynamic> toFirestore({required String chatPartnerId, required String currentUserId}) {
    return {
      'senderId': isUser ? currentUserId : chatPartnerId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    };
  }

  // Método para serializar a JSON si es necesario para otros servicios
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}