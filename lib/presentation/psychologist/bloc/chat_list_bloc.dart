// lib/presentation/psychologist/bloc/chat_list_bloc.dart
// ✅ VERSIÓN CORREGIDA: Busca el campo correcto en Firestore

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/patient_chat_item.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_state.dart';

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
      print('📋 Cargando chats para psicólogo: ${event.userId}');
      
      _chatsSubscription?.cancel();

      // ✅ CORRECCIÓN: Buscar por 'participants' sin orderBy inicialmente
      _chatsSubscription = _firestore
          .collection('chats')
          .where('participants', arrayContains: event.userId)
          .snapshots()
          .listen((snapshot) async {
        
        print('📥 Snapshot recibido: ${snapshot.docs.length} chats encontrados');
        
        List<PatientChatItem> chats = [];
        
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            print('📄 Procesando chat: ${doc.id}');
            print('   - lastMessage: ${data['lastMessage']}');
            print('   - lastMessageTime: ${data['lastMessageTime']}');
            print('   - participants: ${data['participants']}');
            
            if (data['participants'] is! List) {
              print('⚠️ participants no es una lista, saltando...');
              continue;
            }

            final participants = (data['participants'] as List).cast<String>();
            final otherMemberId = participants.firstWhere(
              (id) => id != event.userId,
              orElse: () => '',
            );

            if (otherMemberId.isEmpty) {
              print('⚠️ No se encontró otro participante, saltando...');
              continue;
            }

            print('👤 Cargando datos del paciente: $otherMemberId');

            // Cargar datos del paciente
            final patientDoc = await _firestore
                .collection('patients')
                .doc(otherMemberId)
                .get();
            
            final patientData = patientDoc.data();
            
            if (patientData == null) {
              print('⚠️ No se encontraron datos del paciente, saltando...');
              continue;
            }

            // Cargar estado de usuario (online/offline)
            final userDoc = await _firestore
                .collection('users')
                .doc(otherMemberId)
                .get();
            
            final userData = userDoc.data();
            final bool isOnline = userData?['isOnline'] ?? false;
            final Timestamp? lastSeenTimestamp = userData?['lastSeen'];

            // ✅ CORRECCIÓN: Usar 'lastMessageTime' en lugar de 'lastTimestamp'
            final lastMessageTime = data['lastMessageTime'] as Timestamp?;
            final lastMessage = data['lastMessage'] as String?;

            // Calcular mensajes no leídos
            final messagesSnapshot = await _firestore
                .collection('chats')
                .doc(doc.id)
                .collection('messages')
                .where('receiverId', isEqualTo: event.userId)
                .where('isRead', isEqualTo: false)
                .get();

            final unreadCount = messagesSnapshot.docs.length;

            print('✅ Chat agregado: ${patientData['full_name'] ?? 'Sin nombre'}');
            print('   - Último mensaje: ${lastMessage ?? 'Sin mensajes'}');
            print('   - Mensajes no leídos: $unreadCount');

            chats.add(
              PatientChatItem(
                id: otherMemberId,
                name: patientData['full_name'] as String? ?? 
                      patientData['username'] as String? ?? 
                      'Paciente',
                lastMessage: lastMessage ?? 'No hay mensajes',
                lastMessageTime: lastMessageTime?.toDate() ?? DateTime.now(),
                profileImageUrl: patientData['profile_picture_url'] as String? ?? 
                                'https://via.placeholder.com/60',
                isOnline: isOnline,
                lastSeen: lastSeenTimestamp?.toDate(),
                unreadCount: unreadCount,
                isTyping: false,
              ),
            );
          } catch (e) {
            print('❌ Error procesando chat ${doc.id}: $e');
          }
        }

        // ✅ Ordenar por tiempo del último mensaje (más reciente primero)
        chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

        print('✅ Total chats procesados: ${chats.length}');
        add(ChatsUpdated(chats));
      }, onError: (error) {
        print('❌ Error en stream de chats: $error');
        emit(ChatListError('Error al cargar los chats: $error'));
      });

    } catch (e) {
      print('❌ Error al configurar stream de chats: $e');
      emit(ChatListError('Error al cargar los chats: $e'));
    }
  }

  void _onSearchChats(SearchChats event, Emitter<ChatListState> emit) {
    if (state is ChatListLoaded) {
      final loadedState = state as ChatListLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(loadedState.copyWith(filteredChats: _allChats));
        return;
      }

      final filteredChats = _allChats.where((chat) {
        return chat.name.toLowerCase().contains(query) ||
               chat.lastMessage.toLowerCase().contains(query);
      }).toList();

      print('🔍 Búsqueda: "$query" - ${filteredChats.length} resultados');
      emit(loadedState.copyWith(filteredChats: filteredChats));
    }
  }

  void _onChatsUpdated(ChatsUpdated event, Emitter<ChatListState> emit) {
    _allChats = event.chats;
    print('📊 Estado actualizado: ${_allChats.length} chats totales');
    emit(ChatListLoaded(chats: _allChats, filteredChats: _allChats));
  }

  @override
  Future<void> close() {
    print('🔚 Cerrando ChatListBloc');
    _chatsSubscription?.cancel();
    return super.close();
  }
}