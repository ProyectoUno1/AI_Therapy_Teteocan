// lib/presentation/chat/bloc/chat_event.dart
import 'package:equatable/equatable.dart';

// Clase abstracta base para todos los eventos del chat
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

// Evento para enviar un nuevo mensaje
class SendMessageEvent extends ChatEvent {
  final String message;
  const SendMessageEvent(this.message);
  @override
  List<Object?> get props => [message];
}

// Evento para cargar mensajes del historial
class LoadMessagesEvent extends ChatEvent {
  final String chatId;
  const LoadMessagesEvent({required this.chatId});
  @override
  List<Object?> get props => [chatId];
}

// Evento para cuando se recibe un mensaje (útil para tiempo real o confirmaciones)
class MessageReceivedEvent extends ChatEvent {
  final String message;
  final DateTime timestamp;
  final bool isAI;
  const MessageReceivedEvent(this.message, this.timestamp, {this.isAI = false});
  @override
  List<Object?> get props => [message, timestamp, isAI];
}

// Evento para controlar el indicador de "escribiendo..." de la IA
// Unifica StartTypingEvent y StopTypingEvent en uno solo.
class SetTypingStatusEvent extends ChatEvent { // <-- Asegúrate de que esta clase exista
  final bool isTyping; // <-- Y que tenga esta propiedad
  const SetTypingStatusEvent({required this.isTyping}); // <-- Y este constructor
  @override
  List<Object?> get props => [isTyping];
}

// Elimina o comenta las siguientes líneas si existen para evitar conflictos:
// class StartTypingEvent extends ChatEvent { const StartTypingEvent(); }
// class StopTypingEvent extends ChatEvent { const StopTypingEvent(); }