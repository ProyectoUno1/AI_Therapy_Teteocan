// lib/presentation/chat/views/psychologist_chat_screen.dart
// ✅ VERSIÓN CORREGIDA COMPLETA

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/core/services/e2ee_service.dart';
import 'dart:async';

class PsychologistChatScreen extends StatefulWidget {
  final String psychologistUid;
  final String psychologistName;
  final String profilePictureUrl;

  const PsychologistChatScreen({
    super.key,
    required this.psychologistUid,
    required this.psychologistName,
    required this.profilePictureUrl,
  });

  @override
  State<PsychologistChatScreen> createState() => _PsychologistChatScreenState();
}

class _PsychologistChatScreenState extends State<PsychologistChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _e2eeService = E2EEService();
  
  // ✅ Declarar _currentUserId
  late String _currentUserId;
  late final String _chatId;
  late final ChatRepository _chatRepository;
  late final Stream<DocumentSnapshot> _psychologistStatusStream;
  
  String? _currentUserImageUrl;
  bool _isInitialized = false;
  
  // ✅ Stream controller para mensajes descifrados
  late StreamController<List<MessageModel>> _messagesStreamController;
  StreamSubscription? _firestoreSubscription;

  @override
  void initState() {
    super.initState();
    
    // ✅ Inicializar _currentUserId
    _currentUserId = _auth.currentUser!.uid;
    
    final uids = [_currentUserId, widget.psychologistUid]..sort();
    _chatId = uids.join('_');

    _chatRepository = ChatRepository();
    _messagesStreamController = StreamController<List<MessageModel>>.broadcast();

    _psychologistStatusStream = _firestore
        .collection('users')
        .doc(widget.psychologistUid)
        .snapshots();
    
    print('🔍 DEBUG: Chat ID: $_chatId');
    print('🔍 DEBUG: Current User ID: $_currentUserId');
    print('🔍 DEBUG: Psychologist ID: ${widget.psychologistUid}');
    
    _initializeE2EE();
    _loadCurrentUserImage();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatRepository.markMessagesAsRead(
        chatId: _chatId,
        currentUserId: _currentUserId,
      );
    });
  }

  // ✅ Inicializar E2EE
  Future<void> _initializeE2EE() async {
    try {
      await _e2eeService.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startListeningToMessages();
      }
    } catch (e) {
      print('❌ Error inicializando E2EE: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error inicializando cifrado. Reinicia la app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Escuchar mensajes de Firestore y descifrarlos
  void _startListeningToMessages() {
    _firestoreSubscription = _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) async {
      
      print('🔥 Nuevos mensajes recibidos: ${snapshot.docs.length}');
      
      final messages = <MessageModel>[];
      
      // ✅ Procesar TODOS los documentos primero
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final content = data['content'] as String? ?? '';
        final senderContent = data['senderContent'] as String? ?? '';
        final isE2EE = data['isE2EE'] as bool? ?? false;
        final senderId = data['senderId'] as String? ?? '';
        
        String decryptedContent;
        
        // ✅ SIEMPRE descifrar, sin importar quién lo envió
        if (senderId == _currentUserId) {
          // Descifrar MI versión cifrada
          print('🔓 Descifrando MI mensaje cifrado...');
          try {
            if (senderContent.isEmpty) {
              // Compatibilidad: Si no hay senderContent, intentar content
              decryptedContent = content;
            } else {
              decryptedContent = await _e2eeService.decryptMessage(senderContent);
            }
            print('✅ Mi mensaje descifrado: ${decryptedContent.substring(0, decryptedContent.length > 30 ? 30 : decryptedContent.length)}');
          } catch (e) {
            print('❌ Error descifrando mi mensaje: $e');
            decryptedContent = '🔐 [Error al descifrar mi mensaje]';
          }
        } else {
          // Descifrar mensaje del OTRO usuario
          print('🔓 Descifrando mensaje recibido...');
          try {
            if (content.trim().startsWith('{') && content.contains('encryptedMessage')) {
              decryptedContent = await _e2eeService.decryptMessage(content);
              print('✅ Mensaje recibido descifrado: ${decryptedContent.substring(0, decryptedContent.length > 30 ? 30 : decryptedContent.length)}');
            } else if (isE2EE) {
              try {
                decryptedContent = await _e2eeService.decryptMessage(content);
              } catch (e) {
                decryptedContent = '🔐 [Mensaje cifrado - No disponible]';
              }
            } else {
              decryptedContent = content;
            }
          } catch (e) {
            print('❌ Error descifrando mensaje recibido: $e');
            decryptedContent = '🔐 [Mensaje cifrado - No disponible]';
          }
        }
        
        final timestamp = data['timestamp'] as Timestamp?;
        
        messages.add(MessageModel(
          id: doc.id,
          content: decryptedContent,
          timestamp: timestamp?.toDate() ?? DateTime.now(),
          isUser: senderId == _currentUserId,
          senderId: senderId,
          receiverId: data['receiverId'] as String?,
          isRead: data['isRead'] as bool? ?? false,
        ));
      } // ✅ CERRAR EL FOR AQUÍ
      
      // ✅ Emitir TODOS los mensajes procesados al stream
      if (!_messagesStreamController.isClosed) {
        _messagesStreamController.add(messages);
        print('✅ ${messages.length} mensajes emitidos al stream');
        
        // Scroll automático después de añadir mensajes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  void _loadCurrentUserImage() async {
    try {
      final userDoc = await _firestore.collection('patients').doc(_currentUserId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _currentUserImageUrl = userDoc.data()?['profilePictureUrl'];
        });
      }
    } catch (e) {
      print('Error cargando imagen de usuario: $e');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _messagesStreamController.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Enviar mensaje CIFRADO
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isInitialized) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    print('📤 Enviando mensaje: $messageContent');

    try {
      await _chatRepository.sendHumanMessage(
        chatId: _chatId,
        senderId: _currentUserId,
        receiverId: widget.psychologistUid,
        content: messageContent,
      );
      
      print('✅ Mensaje enviado correctamente');
      
      // ✅ El stream de Firestore actualizará automáticamente la UI
      
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar el mensaje: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ✅ Mostrar indicador si E2EE no está listo
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.psychologistName)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando cifrado seguro...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.profilePictureUrl.isNotEmpty
                  ? NetworkImage(widget.profilePictureUrl)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _psychologistStatusStream,
                builder: (context, snapshot) {
                  bool isOnline = false;
                  String lastSeenText = 'Última vez visto: N/A';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    isOnline = data['isOnline'] as bool? ?? false;
                    final lastSeenTimestamp = data['lastSeen'] as Timestamp?;

                    if (lastSeenTimestamp != null) {
                      final lastSeenDate = lastSeenTimestamp.toDate();
                      final now = DateTime.now();
                      final difference = now.difference(lastSeenDate);

                      if (difference.inMinutes < 1) {
                        lastSeenText = 'En línea';
                      } else if (difference.inHours < 1) {
                        lastSeenText = 'Hace ${difference.inMinutes} min';
                      } else if (difference.inDays < 1) {
                        lastSeenText = 'Hoy a las ${DateFormat('HH:mm').format(lastSeenDate)}';
                      } else if (difference.inDays < 2) {
                        lastSeenText = 'Ayer a las ${DateFormat('HH:mm').format(lastSeenDate)}';
                      } else {
                        lastSeenText = 'El ${DateFormat('dd MMM').format(lastSeenDate)}';
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.psychologistName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.lock, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isOnline ? 'En línea' : lastSeenText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOnline ? Colors.green : theme.textTheme.bodySmall?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              // ✅ Usar el stream de mensajes descifrados
              child: StreamBuilder<List<MessageModel>>(
                stream: _messagesStreamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Descifrando mensajes...'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Inicia una conversación...'),
                    );
                  }

                  final messages = snapshot.data!;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MessageBubble(
                          message: message,
                          isMe: message.isUser,
                          profilePictureUrl: message.isUser 
                              ? _currentUserImageUrl
                              : widget.profilePictureUrl, 
                          isRead: message.isRead,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: Colors.grey[600],
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _isInitialized,
                      decoration: InputDecoration(
                        hintText: _isInitialized 
                            ? 'Escribe un mensaje...' 
                            : 'Inicializando cifrado...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isInitialized 
                          ? theme.colorScheme.primary 
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _isInitialized ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}