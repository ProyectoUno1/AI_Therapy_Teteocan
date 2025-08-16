//lib/data/models/psychologist_chat_item.dart
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PsychologistChatItem extends Equatable {
  final String chatId;
  final String psychologistId;
  final String psychologistName;
  final String? psychologistImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;

  const PsychologistChatItem({
    required this.chatId,
    required this.psychologistId,
    required this.psychologistName,
    this.psychologistImageUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
  });

  factory PsychologistChatItem.fromFirestore({
    required Map<String, dynamic> chatData,
    required Map<String, dynamic> psychologistData,
  }) {
    
    final psychologistId = psychologistData['uid'] as String;
    final otherParticipantId = chatData['participants']
        .firstWhere((id) => id != chatData['patientId']); 
    
    
    final lastMessage = chatData['lastMessage'] as String? ?? '';
    final lastMessageTime = (chatData['lastTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Aquí se extrae la información del psicólogo usando tu PsychologistModel
    final psychologistName = psychologistData['fullName'] as String? ?? 'Psicólogo Desconocido';
    final psychologistImageUrl = psychologistData['profilePictureUrl'] as String?;
    
    
    final unreadCount = chatData['unreadCount'] as int? ?? 0;
    final isOnline = psychologistData['isOnline'] as bool? ?? false;
    final isTyping = chatData['isTyping'] as bool? ?? false;

    return PsychologistChatItem(
      chatId: chatData['chatId'] as String,
      psychologistId: psychologistId,
      psychologistName: psychologistName,
      psychologistImageUrl: psychologistImageUrl,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount,
      isOnline: isOnline,
      isTyping: isTyping,
    );
  }

  @override
  List<Object?> get props => [
    chatId,
    psychologistId,
    psychologistName,
    psychologistImageUrl,
    lastMessage,
    lastMessageTime,
    unreadCount,
    isOnline,
    isTyping,
  ];
}