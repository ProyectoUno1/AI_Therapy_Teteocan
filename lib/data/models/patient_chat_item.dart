// lib/data/models/patient_chat_item.dart
class PatientChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String profileImageUrl;
  final bool isOnline;
  final int unreadCount;
  final bool isTyping;

  PatientChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.profileImageUrl,
    required this.isOnline,
    required this.unreadCount,
    required this.isTyping,
  });
}