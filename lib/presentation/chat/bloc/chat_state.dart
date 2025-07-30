import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';

enum ChatStatus { initial, loading, success, error, sending }

class ChatState extends Equatable {
  final List<MessageModel> messages;
  final ChatStatus status;
  final String? errorMessage;
  final bool isTyping;

  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.initial,
    this.errorMessage,
    this.isTyping = false,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    ChatStatus? status,
    String? errorMessage,
    bool? isTyping,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [messages, status, errorMessage, isTyping];
}
