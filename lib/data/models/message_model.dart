// lib/data/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isAI;
  final String? attachmentUrl;
  final MessageType type;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isAI = false,
    this.attachmentUrl,
    this.type = MessageType.text,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isAI: json['isAI'] as bool? ?? false,
      attachmentUrl: json['attachmentUrl'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAI': isAI,
      'attachmentUrl': attachmentUrl,
      'type': type.toString().split('.').last,
    };
  }
}

enum MessageType { text, image, audio, video, file }
