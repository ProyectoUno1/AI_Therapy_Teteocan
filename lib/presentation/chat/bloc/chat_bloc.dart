import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_state.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/core/services/ai_chat_api_service.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();
const int _freeMessageLimit = 5;

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final AiChatApiService _aiChatApiService;

  ChatBloc(this._chatRepository, this._aiChatApiService) : super(const ChatState()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<SetTypingStatusEvent>(_onSetTypingStatus);
    on<InitAIChat>(_onInitAIChat);
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final messages = await _chatRepository.loadMessages(event.chatId);
      final userMessageCount = messages.where((msg) => msg.isUser).length;
      final isLimitReached = userMessageCount >= _freeMessageLimit;
      
      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: messages,
        isMessageLimitReached: isLimitReached,
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
    emit(state.copyWith(status: ChatStatus.sending, isTyping: true));
    try {
      final newMessage = MessageModel(
        id: _uuid.v4(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
        senderId: event.userId!,
      );

      final updatedMessages = List<MessageModel>.from(state.messages)..add(newMessage);
      emit(state.copyWith(messages: updatedMessages));

      await _aiChatApiService.sendMessage(event.message);

      emit(state.copyWith(
        status: ChatStatus.loaded,
        isTyping: false,
      ));

    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
        isTyping: false,
      ));
    }
  }

  Future<void> _onSetTypingStatus(
    SetTypingStatusEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isTyping: event.isTyping));
  }
  
  Future<void> _onInitAIChat(
  InitAIChat event,
  Emitter<ChatState> emit,
) async {
  try {
    final chatId = await _chatRepository.getOrCreateChatId(event.userId);
    add(LoadMessagesEvent(chatId: chatId)); 
  } catch (e) {
    emit(state.copyWith(
      status: ChatStatus.error,
      errorMessage: e.toString(),
    ));
  }
}
}