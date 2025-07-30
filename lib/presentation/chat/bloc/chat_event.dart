import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatEvent {
  final String message;
  final bool isAI;

  const SendMessageEvent({required this.message, this.isAI = false});

  @override
  List<Object?> get props => [message, isAI];
}

class LoadMessagesEvent extends ChatEvent {
  final String chatId;

  const LoadMessagesEvent({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class MessageReceivedEvent extends ChatEvent {
  final String message;
  final bool isAI;
  final DateTime timestamp;

  const MessageReceivedEvent({
    required this.message,
    required this.isAI,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, isAI, timestamp];
}

class StartTypingEvent extends ChatEvent {
  const StartTypingEvent();
}

class StopTypingEvent extends ChatEvent {
  const StopTypingEvent();
}

class ClearChatEvent extends ChatEvent {
  const ClearChatEvent();
}
