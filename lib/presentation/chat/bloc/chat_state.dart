// chat_state.dart
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart'; 

// Define los posibles estados del chat
enum ChatStatus {
  initial,
  loading,
  loaded, 
  sending,
  error,
}

class ChatState extends Equatable {
  final ChatStatus status;
  final List<MessageModel> messages;
  final String? errorMessage;
  final bool isTyping;
  final bool isMessageLimitReached; 
  final bool isLoading;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
    this.isTyping = false, 
    this.isMessageLimitReached = false, 
    this.isLoading = false,
  });
  
  ChatState copyWith({
    ChatStatus? status,
    List<MessageModel>? messages,
    String? errorMessage,
    bool? isTyping,
    bool? isMessageLimitReached, 
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
      isTyping: isTyping ?? this.isTyping,
      isMessageLimitReached: isMessageLimitReached ?? this.isMessageLimitReached,
      isLoading: isLoading,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage, isTyping, isMessageLimitReached, isLoading];
}