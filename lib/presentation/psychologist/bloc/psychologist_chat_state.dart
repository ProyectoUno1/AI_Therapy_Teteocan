// lib/presentation/psychologist/bloc/psychologist_chat_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';

abstract class PsychologistChatState extends Equatable {
  const PsychologistChatState();
  @override
  List<Object?> get props => [];
}

class PsychologistChatInitial extends PsychologistChatState {}

class PsychologistChatLoading extends PsychologistChatState {}

class PsychologistChatLoaded extends PsychologistChatState {
  final List<MessageModel> messages;
  const PsychologistChatLoaded(this.messages);
  @override
  List<Object?> get props => [messages];
}

class PsychologistChatError extends PsychologistChatState {
  final String message;
  const PsychologistChatError(this.message);
  @override
  List<Object?> get props => [message];
}