// lib/presentation/psychologist/bloc/psychologist_chat_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_state.dart';
import 'package:ai_therapy_teteocan/core/services/e2ee_service.dart';

class PsychologistChatBloc
    extends Bloc<PsychologistChatEvent, PsychologistChatState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatRepository _chatRepository = ChatRepository();
  final E2EEService _e2eeService = E2EEService();
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

      // ✅ Escuchar cambios en Firestore
      _messagesSubscription = _firestore
          .collection('chats')
          .doc(event.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen(
            (snapshot) {
              print(
                '📥 Snapshot recibido con ${snapshot.docs.length} mensajes',
              );

              // ✅ Procesar mensajes de forma asíncrona
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

  /// Procesa y descifra mensajes de forma asíncrona
  Future<void> _processMessages(
    List<QueryDocumentSnapshot> docs,
    String currentUserId,
  ) async {
    List<MessageModel> messages = [];

    print('🔄 Procesando ${docs.length} mensajes...');

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        String decryptedContent = data['content'] ?? '';

        print('📄 Mensaje ID: ${doc.id}');
        print(
          '📝 Contenido raw (primeros 50 chars): ${decryptedContent.substring(0, decryptedContent.length > 50 ? 50 : decryptedContent.length)}',
        );

        // ✅ Verificar si el mensaje está cifrado
        if (decryptedContent.startsWith('{') &&
            decryptedContent.contains('encryptedMessage')) {
          print('🔐 Mensaje cifrado detectado, intentando descifrar...');

          try {
            decryptedContent = await _e2eeService.decryptMessage(
              decryptedContent,
            );
            print('✅ Mensaje descifrado: $decryptedContent');
          } catch (e) {
            print('❌ Error descifrando mensaje: $e');
            decryptedContent = '[Error al descifrar mensaje]';
          }
        } else {
          print('📝 Mensaje en texto plano');
        }

        // Crear modelo de mensaje
        final message = MessageModel(
          id: doc.id,
          content: decryptedContent, // ✅ Solo usar 'content'
          isUser: data['senderId'] == currentUserId,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'],
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );

        messages.add(message);
      } catch (e) {
        print('⚠️ Error procesando mensaje ${doc.id}: $e');
      }
    }

    print('✅ Total mensajes procesados: ${messages.length}');

    // Emitir evento con mensajes descifrados
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

    // ✅ Usar ChatRepository que cifra automáticamente
    await _chatRepository.sendHumanMessage(
      chatId: event.chatId,
      senderId: event.senderId,
      receiverId: event.receiverId!,
      content: event.content,
    );

    print('✅ Mensaje enviado y cifrado exitosamente');

    // ✅ ELIMINAR estas líneas que sobrescribían lastMessage
    // await _firestore.collection('chats').doc(event.chatId).set({
    //   'lastMessage': '[Mensaje cifrado]',
    //   'lastTimestamp': FieldValue.serverTimestamp(),
    //   'participants': [event.senderId, event.receiverId],
    // }, SetOptions(merge: true));
    
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
