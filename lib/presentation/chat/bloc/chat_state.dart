// chat_state.dart (OPTIMIZADO)
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart'; 

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
  final int usedMessages;
  final int messageLimit;
  final bool isPremium;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
    this.isTyping = false, 
    this.isMessageLimitReached = false, 
    this.usedMessages = 0,
    this.messageLimit = 5,
    this.isPremium = false,
  });
  
  bool get isLoading => status == ChatStatus.sending || status == ChatStatus.loading;
  bool get canSendMessage => !isLoading && !isMessageLimitReached;
  bool get shouldShowWarning => !isPremium && usedMessages >= messageLimit - 1 && usedMessages < messageLimit;
  
  ChatState copyWith({
    ChatStatus? status,
    List<MessageModel>? messages,
    String? errorMessage,
    bool? isTyping,
    bool? isMessageLimitReached, 
    int? usedMessages,
    int? messageLimit,
    bool? isPremium,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
      isTyping: isTyping ?? this.isTyping,
      isMessageLimitReached: isMessageLimitReached ?? this.isMessageLimitReached,
      usedMessages: usedMessages ?? this.usedMessages,
      messageLimit: messageLimit ?? this.messageLimit,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    messages, 
    errorMessage, 
    isTyping, 
    isMessageLimitReached, 
    usedMessages,
    messageLimit,
    isPremium,
  ];
}