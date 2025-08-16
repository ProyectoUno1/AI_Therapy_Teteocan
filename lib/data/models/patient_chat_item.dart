// lib/data/models/patient_chat_item.dart
import 'package:equatable/equatable.dart';

class PatientChatItem extends Equatable {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen; 
  final int unreadCount;
  final bool isTyping;

  const PatientChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen, 
    this.unreadCount = 0,
    this.isTyping = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    lastMessage,
    lastMessageTime,
    profileImageUrl,
    isOnline,
    lastSeen,
    unreadCount,
    isTyping,
  ];
  
  PatientChatItem copyWith({
    String? id,
    String? name,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? profileImageUrl,
    bool? isOnline,
    DateTime? lastSeen,
    int? unreadCount,
    bool? isTyping,
  }) {
    return PatientChatItem(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}