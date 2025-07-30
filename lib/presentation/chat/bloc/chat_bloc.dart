import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  // TODO: Inyectar el repositorio de chat cuando lo creemos
  // final ChatRepository _chatRepository;

  ChatBloc() : super(const ChatState()) {
    on<SendMessageEvent>(_onSendMessage);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<StartTypingEvent>(_onStartTyping);
    on<StopTypingEvent>(_onStopTyping);
    on<ClearChatEvent>(_onClearChat);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final newMessage = MessageModel(
        id: DateTime.now().toString(),
        senderId: 'user', // TODO: Obtener el ID real del usuario
        content: event.message,
        timestamp: DateTime.now(),
        isAI: event.isAI,
      );

      final updatedMessages = [...state.messages, newMessage];
      emit(
        state.copyWith(messages: updatedMessages, status: ChatStatus.success),
      );

      // Si es un mensaje para la AI, simular respuesta
      if (!event.isAI) {
        emit(state.copyWith(isTyping: true));

        // Simular delay de respuesta (esto se reemplazará con la llamada real a la API)
        await Future.delayed(const Duration(seconds: 1));

        final aiResponse = MessageModel(
          id: DateTime.now().toString(),
          senderId: 'aurora',
          content: 'Estoy aquí para escucharte. ¿Quieres hablar más sobre eso?',
          timestamp: DateTime.now(),
          isAI: true,
        );

        final messagesWithAiResponse = [...updatedMessages, aiResponse];
        emit(
          state.copyWith(
            messages: messagesWithAiResponse,
            isTyping: false,
            status: ChatStatus.success,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Error al enviar el mensaje: $e',
        ),
      );
    }
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      // TODO: Implementar carga de mensajes desde el repositorio
      // final messages = await _chatRepository.getMessages(event.chatId);
      // emit(state.copyWith(
      //   messages: messages,
      //   status: ChatStatus.success,
      // ));
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Error al cargar los mensajes: $e',
        ),
      );
    }
  }

  void _onMessageReceived(MessageReceivedEvent event, Emitter<ChatState> emit) {
    final newMessage = MessageModel(
      id: DateTime.now().toString(),
      senderId: event.isAI ? 'aurora' : 'other',
      content: event.message,
      timestamp: event.timestamp,
      isAI: event.isAI,
    );

    final updatedMessages = [...state.messages, newMessage];
    emit(state.copyWith(messages: updatedMessages, status: ChatStatus.success));
  }

  void _onStartTyping(StartTypingEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(isTyping: true));
  }

  void _onStopTyping(StopTypingEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(isTyping: false));
  }

  void _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) {
    emit(const ChatState());
  }
}
