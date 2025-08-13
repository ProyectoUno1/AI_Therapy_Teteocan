// lib/presentation/chat/bloc/chat_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_state.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;

  ChatBloc(this._chatRepository) : super(const ChatState()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<SetTypingStatusEvent>(_onSetTypingStatus);
    
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final messages = await _chatRepository.loadMessages(event.chatId);
      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.sending));
    try {
      const String currentChatId = 'ai-chat';

      final newMessage = MessageModel(
        id: _uuid.v4(),
        content: event.message, 
        isUser: true, 
        timestamp: DateTime.now(),
      );

      final updatedMessages = List<MessageModel>.from(state.messages)..add(newMessage);
      emit(state.copyWith(messages: updatedMessages));
      emit(state.copyWith(isTyping: true));

      final aiResponseContent = await _chatRepository.sendAIMessage(currentChatId, event.message);

      final aiMessage = MessageModel(
        id: _uuid.v4(),
        content: aiResponseContent, 
        isUser: false, 
        timestamp: DateTime.now(),

      );

      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: List<MessageModel>.from(state.messages)..add(aiMessage),
      ));
      emit(state.copyWith(isTyping: false));

    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
      ));
      emit(state.copyWith(isTyping: false));
    }
  }

  void _onSetTypingStatus(
    SetTypingStatusEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(isTyping: event.isTyping));
  }
}