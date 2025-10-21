import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/patient_chat_item.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_state.dart';
import 'dart:developer'; 

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _chatsSubscription;
  List<PatientChatItem> _allChats = [];

  ChatListBloc() : super(ChatListInitial()) {
    on<LoadChats>(_onLoadChats);
    on<ChatsUpdated>(_onChatsUpdated);
    on<SearchChats>(_onSearchChats);
  }

  Future<void> _onLoadChats(LoadChats event, Emitter<ChatListState> emit) async {
    emit(ChatListLoading());
    try {
      _chatsSubscription?.cancel();

      _chatsSubscription = _firestore.collection('chats')
          .where('participants', arrayContains: event.userId)
          .orderBy('lastTimestamp', descending: true)
          .snapshots()
          .listen((snapshot) async {
        List<PatientChatItem> chats = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['participants'] is! List) continue;

          final participants = (data['participants'] as List).cast<String>();
          final otherMemberId = participants.firstWhere(
            (id) => id != event.userId,
            orElse: () => '',
          );

          if (otherMemberId.isNotEmpty) {
            final patientDoc = await _firestore.collection('patients').doc(otherMemberId).get();
            final patientData = patientDoc.data();
            final userDoc = await _firestore.collection('users').doc(otherMemberId).get();
            final userData = userDoc.data();
            final bool isOnline = userData?['isOnline'] ?? false;
            final Timestamp? lastSeenTimestamp = userData?['lastSeen'];

            if (patientData != null) {
              chats.add(
                PatientChatItem(
                  id: otherMemberId,
                  name: patientData['full_name'] as String? ?? patientData['username'] as String? ?? 'Paciente',
                  lastMessage: data['lastMessage'] as String? ?? 'No hay mensajes',
                  lastMessageTime: (data['lastTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  profileImageUrl: patientData['profile_picture_url'] as String? ?? 'https://via.placeholder.com/60',
                  isOnline: isOnline,
                  lastSeen: lastSeenTimestamp?.toDate(),
                  unreadCount: 0,
                  isTyping: false,
                ),
              );
            }
          }
        }
        add(ChatsUpdated(chats));
      });
    } catch (e) {
      emit(ChatListError('Error al cargar los chats: $e'));
    }
  }

  void _onSearchChats(SearchChats event, Emitter<ChatListState> emit) {
    if (state is ChatListLoaded) {
      final loadedState = state as ChatListLoaded;
      final query = event.query.toLowerCase();

      final filteredChats = _allChats.where((chat) {
        return chat.name.toLowerCase().contains(query) ||
               chat.lastMessage.toLowerCase().contains(query);
      }).toList();

      emit(loadedState.copyWith(filteredChats: filteredChats));
    }
  }

  void _onChatsUpdated(ChatsUpdated event, Emitter<ChatListState> emit) {
    _allChats = event.chats;
    emit(ChatListLoaded(chats: _allChats, filteredChats: _allChats));
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}