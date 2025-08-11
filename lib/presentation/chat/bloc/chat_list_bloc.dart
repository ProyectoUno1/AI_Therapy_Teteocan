// lib/presentation/chat/bloc/chat_list_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_chat_item.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();
  @override
  List<Object?> get props => [];
}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<PsychologistChatItem> chatRooms;
  const ChatListLoaded(this.chatRooms);
  @override
  List<Object?> get props => [chatRooms];
}

class ChatListError extends ChatListState {
  final String message;
  const ChatListError(this.message);
  @override
  List<Object?> get props => [message];
}


class ChatListCubit extends Cubit<ChatListState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId;
  StreamSubscription? _chatSubscription;

  ChatListCubit({required this.currentUserId}) : super(ChatListLoading()) {
    _loadChats();
  }

  void _loadChats() {
    _chatSubscription?.cancel();
    _chatSubscription = _firestore.collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      try {
        final List<PsychologistChatItem> chatRooms = [];
        for (var chatDoc in snapshot.docs) {
          final chatData = chatDoc.data();
          final participants = (chatData['participants'] as List<dynamic>).cast<String>();
          final otherParticipantUid = participants.firstWhere(
            (uid) => uid != currentUserId,
            orElse: () => '',
          );

          if (otherParticipantUid.isNotEmpty) {
            final psychologistDoc = await _firestore.collection('psychologist_professional_info').doc(otherParticipantUid).get();
            final psychologistData = psychologistDoc.data();

            if (psychologistData != null) {
              chatRooms.add(
                PsychologistChatItem(
                  chatId: chatDoc.id,
                  psychologistId: otherParticipantUid,
                  psychologistName: psychologistData['fullName'] as String? ?? 'Psicólogo',
                  psychologistImageUrl: psychologistData['profilePictureUrl'] as String?,
                  lastMessage: chatData['lastMessage'] as String? ?? 'Inicia una conversación',
                  lastMessageTime: (chatData['lastTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                
                  unreadCount: 0,
                  isOnline: false,
                  isTyping: false,
                ),
              );
            }
          }
        }
        emit(ChatListLoaded(chatRooms));
      } catch (e) {
        emit(ChatListError('Error al cargar los chats: $e'));
      }
    });
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}