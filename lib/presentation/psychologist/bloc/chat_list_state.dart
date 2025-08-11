// lib/presentation/psychologist/bloc/chat_list_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_chat_item.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();
  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<PatientChatItem> chats;
 
  final List<PatientChatItem> filteredChats;

  const ChatListLoaded({required this.chats, this.filteredChats = const []});

  // Sobrescribe el método copyWith para facilitar la actualización del estado
  ChatListLoaded copyWith({
    List<PatientChatItem>? chats,
    List<PatientChatItem>? filteredChats,
  }) {
    return ChatListLoaded(
      chats: chats ?? this.chats,
      filteredChats: filteredChats ?? this.filteredChats,
    );
  }

  @override
  List<Object?> get props => [chats, filteredChats];
}

class ChatListError extends ChatListState {
  final String message;
  const ChatListError(this.message);
  @override
  List<Object?> get props => [message];
}