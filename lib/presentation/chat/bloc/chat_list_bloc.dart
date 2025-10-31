// lib/presentation/chat/bloc/chat_list_bloc.dart
// ✅ VERSIÓN CORREGIDA: Vista de paciente

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
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
    print('📋 Cargando chats para paciente: $currentUserId');
    
    _chatSubscription?.cancel();
    
    // ✅ CORRECCIÓN: Remover orderBy para evitar necesitar índice compuesto
    _chatSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) async {
      try {
        print('📥 Snapshot recibido: ${snapshot.docs.length} chats');
        
        final List<PsychologistChatItem> chatRooms = [];
        
        for (var chatDoc in snapshot.docs) {
          try {
            final chatData = chatDoc.data();
            
            print('📄 Procesando chat: ${chatDoc.id}');
            print('   - lastMessage: ${chatData['lastMessage']}');
            print('   - lastMessageTime: ${chatData['lastMessageTime']}');
            
            if (!chatData.containsKey('participants')) {
              print('⚠️ Chat sin participants, saltando...');
              continue;
            }
            
            final participants = (chatData['participants'] as List<dynamic>).cast<String>();
            final otherParticipantUid = participants.firstWhere(
              (uid) => uid != currentUserId,
              orElse: () => '',
            );

            if (otherParticipantUid.isEmpty) {
              print('⚠️ No se encontró otro participante, saltando...');
              continue;
            }

            print('👤 Cargando datos del psicólogo: $otherParticipantUid');
            
            // Cargar datos del psicólogo
            final psychologistDoc = await _firestore
                .collection('psychologists')
                .doc(otherParticipantUid)
                .get();
            
            final psychologistData = psychologistDoc.data();

            if (psychologistData == null) {
              print('⚠️ No se encontraron datos del psicólogo, saltando...');
              continue;
            }

            // Cargar estado online del psicólogo
            final userDoc = await _firestore
                .collection('users')
                .doc(otherParticipantUid)
                .get();
            
            final userData = userDoc.data();
            final isOnline = userData?['isOnline'] ?? false;

            // Calcular mensajes no leídos
            final messagesSnapshot = await _firestore
                .collection('chats')
                .doc(chatDoc.id)
                .collection('messages')
                .where('receiverId', isEqualTo: currentUserId)
                .where('isRead', isEqualTo: false)
                .get();

            final unreadCount = messagesSnapshot.docs.length;

            // ✅ CORRECCIÓN: Usar 'lastMessageTime' en lugar de 'lastTimestamp'
            final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
            final lastMessage = chatData['lastMessage'] as String?;

            print('✅ Chat agregado: ${psychologistData['fullName'] ?? 'Sin nombre'}');
            print('   - Último mensaje: ${lastMessage ?? 'Sin mensajes'}');
            print('   - No leídos: $unreadCount');

            chatRooms.add(
              PsychologistChatItem(
                chatId: chatDoc.id,
                psychologistId: otherParticipantUid,
                psychologistName: psychologistData['fullName'] as String? ?? 
                                 psychologistData['full_name'] as String? ??
                                 'Psicólogo',
                profilePictureUrl: psychologistData['profilePictureUrl'] as String? ??
                                  psychologistData['profile_picture_url'] as String?,
                lastMessage: lastMessage ?? 'Inicia una conversación',
                lastMessageTime: lastMessageTime?.toDate() ?? DateTime.now(),
                unreadCount: unreadCount,
                isOnline: isOnline,
                isTyping: false,
              ),
            );
          } catch (e) {
            print('❌ Error procesando chat ${chatDoc.id}: $e');
          }
        }

        // ✅ Ordenar por tiempo del último mensaje (más reciente primero)
        chatRooms.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

        print('✅ Total chats del paciente: ${chatRooms.length}');
        emit(ChatListLoaded(chatRooms));
        
      } catch (e) {
        print('❌ Error en stream de chats del paciente: $e');
        emit(ChatListError('Error al cargar los chats: $e'));
      }
    }, onError: (error) {
      print('❌ Error en listener de chats: $error');
      emit(ChatListError('Error al cargar los chats: $error'));
    });
  }

  @override
  Future<void> close() {
    print('🔚 Cerrando ChatListCubit del paciente');
    _chatSubscription?.cancel();
    return super.close();
  }
}