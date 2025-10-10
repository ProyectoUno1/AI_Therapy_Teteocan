// lib/presentation/chat/bloc/chat_event.dart
import 'package:equatable/equatable.dart';

// Clase base para todos los eventos del chat
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

// Evento para enviar un nuevo mensaje
class SendMessageEvent extends ChatEvent {
  final String message;
  final String userId;
  
  const SendMessageEvent(this.message, this.userId);
  
  @override
  List<Object?> get props => [message, userId];
}

// Evento para cargar mensajes del historial
class LoadMessagesEvent extends ChatEvent {
  final String chatId;
  const LoadMessagesEvent({required this.chatId});
  @override
  List<Object?> get props => [chatId];
}

// Evento para cuando se recibe un mensaje 
class MessageReceivedEvent extends ChatEvent {
  final String message;
  final DateTime timestamp;
  final bool isAI;
  const MessageReceivedEvent(this.message, this.timestamp, {this.isAI = false});
  @override
  List<Object?> get props => [message, timestamp, isAI];
}

// Evento para controlar el indicador de "escribiendo..." de la IA
class SetTypingStatusEvent extends ChatEvent { 
  final bool isTyping; 
  const SetTypingStatusEvent({required this.isTyping}); 
  @override
  List<Object?> get props => [isTyping];
}
class InitAIChat extends ChatEvent {
  final String userId;

  const InitAIChat(this.userId);

  @override
  List<Object> get props => [userId];
}