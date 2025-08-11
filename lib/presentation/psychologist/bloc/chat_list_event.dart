// lib/presentation/psychologist/bloc/chat_list_event.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/patient_chat_item.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object?> get props => [];
}

class LoadChats extends ChatListEvent {
  final String userId;
  const LoadChats(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ChatsUpdated extends ChatListEvent {
  final List<PatientChatItem> chats;
  const ChatsUpdated(this.chats);
  @override
  List<Object?> get props => [chats];
}

class SearchChats extends ChatListEvent {
  final String query;
  const SearchChats(this.query);
  @override
  List<Object?> get props => [query];
}