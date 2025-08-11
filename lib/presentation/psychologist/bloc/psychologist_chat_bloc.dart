// lib/presentation/psychologist/bloc/psychologist_chat_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _messagesSubscription;

  ChatBloc() : super(ChatInitial()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessage>(_onSendMessage);
    on<MessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _messagesSubscription?.cancel();

      
      final currentUserId = event.senderId;

      _messagesSubscription = _firestore
          .collection('chats')
          .doc(event.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
            List<MessageModel> messages = snapshot.docs.map((doc) {
              return MessageModel.fromFirestore(doc, currentUserId);
            }).toList();

            add(MessagesUpdated(messages));
          });
    } catch (e) {
      emit(ChatError('Error al cargar mensajes: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(event.chatId)
          .collection('messages');

      await messageRef.add({
        'content': event.content,
        'senderId': event.senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _firestore.collection('chats').doc(event.chatId).update({
        'lastMessage': event.content,
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al enviar el mensaje: $e');
    }
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(ChatLoaded(event.messages));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
