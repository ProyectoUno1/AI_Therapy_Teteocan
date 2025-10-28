// lib/presentation/psychologist/bloc/psychologist_chat_event.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';

abstract class PsychologistChatEvent extends Equatable {
  const PsychologistChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadChatMessages extends PsychologistChatEvent {
  final String chatId;
  final String senderId; 
  
  const LoadChatMessages(this.chatId, this.senderId);
  
  @override
  List<Object?> get props => [chatId, senderId];
}

class SendMessage extends PsychologistChatEvent {
  final String chatId;
  final String content;
  final String senderId;
  final String? receiverId; // ✅ AGREGADO
  
  const SendMessage({
    required this.chatId,
    required this.content,
    required this.senderId,
    this.receiverId, // ✅ AGREGADO
  });
  
  @override
  List<Object?> get props => [chatId, content, senderId, receiverId];
}

class MessagesUpdated extends PsychologistChatEvent {
  final List<MessageModel> messages;
  
  const MessagesUpdated(this.messages);
  
  @override
  List<Object?> get props => [messages];
}