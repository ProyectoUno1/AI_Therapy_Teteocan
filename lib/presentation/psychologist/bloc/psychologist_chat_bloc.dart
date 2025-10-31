// lib/presentation/psychologist/bloc/psychologist_chat_bloc.dart
// ✅ VERSIÓN SIN E2EE

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_state.dart';

class PsychologistChatBloc
    extends Bloc<PsychologistChatEvent, PsychologistChatState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatRepository _chatRepository = ChatRepository();
  StreamSubscription? _messagesSubscription;

  PsychologistChatBloc() : super(PsychologistChatInitial()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessage>(_onSendMessage);
    on<MessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<PsychologistChatState> emit,
  ) async {
    emit(PsychologistChatLoading());

    try {
      print('📨 Cargando mensajes del chat: ${event.chatId}');
      print('👤 Usuario actual: ${event.senderId}');

      _messagesSubscription?.cancel();

      final currentUserId = event.senderId;

      // Escuchar cambios en Firestore
      _messagesSubscription = _firestore
          .collection('chats')
          .doc(event.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              print('📥 Snapshot recibido con ${snapshot.docs.length} mensajes');
              _processMessages(snapshot.docs, currentUserId);
            },
            onError: (error) {
              print('❌ Error en stream: $error');
              emit(PsychologistChatError('Error al cargar mensajes: $error'));
            },
          );
    } catch (e) {
      print('❌ Error en _onLoadChatMessages: $e');
      emit(PsychologistChatError('Error al cargar mensajes: $e'));
    }
  }

  /// Procesa mensajes desde Firestore
  void _processMessages(
    List<QueryDocumentSnapshot> docs,
    String currentUserId,
  ) {
    List<MessageModel> messages = [];

    print('🔄 Procesando ${docs.length} mensajes...');

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final content = data['content'] ?? '';

        print('📄 Mensaje ID: ${doc.id}');
        print('📝 Contenido (primeros 50 chars): ${content.substring(0, content.length > 50 ? 50 : content.length)}');

        // Crear modelo de mensaje
        final message = MessageModel(
          id: doc.id,
          content: content, // Texto plano o encriptado (backend lo maneja)
          isUser: data['senderId'] == currentUserId,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'],
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );

        messages.add(message);
      } catch (e) {
        print('⚠️ Error procesando mensaje ${doc.id}: $e');
      }
    }

    print('✅ Total mensajes procesados: ${messages.length}');

    // Emitir evento con mensajes procesados
    add(MessagesUpdated(messages));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<PsychologistChatState> emit,
  ) async {
    try {
      print('📤 Enviando mensaje...');
      print('📋 Chat ID: ${event.chatId}');
      print('👤 Sender: ${event.senderId}');
      print('👥 Receiver: ${event.receiverId}');
      print('💬 Contenido: ${event.content}');

      if (event.receiverId == null) {
        print('❌ Error: receiverId es null');
        emit(PsychologistChatError('Error: ID del destinatario no disponible'));
        return;
      }

      // Enviar mensaje (el backend se encarga de la encriptación)
      await _chatRepository.sendHumanMessage(
        chatId: event.chatId,
        senderId: event.senderId,
        receiverId: event.receiverId!,
        content: event.content,
      );

      print('✅ Mensaje enviado exitosamente');
    } catch (e) {
      print('❌ Error al enviar el mensaje: $e');
      print('Stack trace: ${StackTrace.current}');
      emit(PsychologistChatError('Error al enviar el mensaje: $e'));
    }
  }

  void _onMessagesUpdated(
    MessagesUpdated event,
    Emitter<PsychologistChatState> emit,
  ) {
    print('📝 Actualizando UI con ${event.messages.length} mensajes');
    emit(PsychologistChatLoaded(event.messages));
  }

  @override
  Future<void> close() {
    print('🔚 Cerrando PsychologistChatBloc');
    _messagesSubscription?.cancel();
    return super.close();
  }
}