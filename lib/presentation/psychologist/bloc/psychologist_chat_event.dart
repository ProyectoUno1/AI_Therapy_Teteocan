// lib/presentation/psychologist/bloc/psychologist_chat_event.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadChatMessages extends ChatEvent {
  final String chatId;
  final String senderId; 
  const LoadChatMessages(this.chatId, this.senderId);
  @override
  List<Object?> get props => [chatId, senderId];
}

class SendMessage extends ChatEvent {
  final String chatId;
  final String content;
  final String senderId;
  const SendMessage({required this.chatId, required this.content, required this.senderId});
  @override
  List<Object?> get props => [chatId, content, senderId];
}

class MessagesUpdated extends ChatEvent {
  final List<MessageModel> messages;
  const MessagesUpdated(this.messages);
  @override
  List<Object?> get props => [messages];
}