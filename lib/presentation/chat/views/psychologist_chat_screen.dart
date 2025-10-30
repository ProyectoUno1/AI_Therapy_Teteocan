// lib/presentation/chat/views/psychologist_chat_screen.dart
// ✅ VERSIÓN CON E2EE CORREGIDA

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/core/services/e2ee_service.dart';

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
  final _e2eeService = E2EEService(); // ✅ Agregar servicio E2EE
  
  late final String _chatId;
  late final ChatRepository _chatRepository;
  late final Stream<DocumentSnapshot> _psychologistStatusStream;
  
  String? _currentUserImageUrl;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final currentUserUid = _auth.currentUser!.uid;
    final uids = [currentUserUid, widget.psychologistUid]..sort();
    _chatId = uids.join('_');

    _chatRepository = ChatRepository();

    _psychologistStatusStream = _firestore
        .collection('users')
        .doc(widget.psychologistUid)
        .snapshots();
    
    _initializeE2EE();
    _loadCurrentUserImage();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatRepository.markMessagesAsRead(
        chatId: _chatId,
        currentUserId: currentUserUid,
      );
    });
  }

  // ✅ Inicializar E2EE
  Future<void> _initializeE2EE() async {
    try {
      await _e2eeService.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
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

  void _loadCurrentUserImage() async {
    final currentUserUid = _auth.currentUser!.uid;
    try {
      final userDoc = await _firestore.collection('patients').doc(currentUserUid).get();
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ Enviar mensaje CIFRADO
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isInitialized) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    _scrollToBottom();

    try {
      // ✅ Cifrar mensaje antes de enviar
      await _chatRepository.sendHumanMessage(
        chatId: _chatId,
        senderId: _auth.currentUser!.uid,
        receiverId: widget.psychologistUid,
        content: messageContent,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar el mensaje: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✅ Descifrar mensaje individual
  Future<String> _decryptMessageContent(Map<String, dynamic> data) async {
    try {
      final content = data['content'] as String? ?? '';
      final isE2EE = data['isE2EE'] as bool? ?? false;

      // Si está marcado como E2EE, intentar descifrar
      if (isE2EE && content.startsWith('{') && content.contains('encryptedMessage')) {
        return await _e2eeService.decryptMessage(content);
      }
      
      // Si no está marcado, retornar texto plano
      return content;
    } catch (e) {
      print('⚠️ Error descifrando: $e');
      return '[Mensaje cifrado - Error al descifrar]';
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
                          // ✅ Indicador de cifrado
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
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(_chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Inicia una conversación...'),
                    );
                  }

                  // ✅ Construir lista con FutureBuilder para descifrar
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      
                      return FutureBuilder<String>(
                        future: _decryptMessageContent(data),
                        builder: (context, decryptSnapshot) {
                          String displayContent;
                          
                          if (decryptSnapshot.connectionState == ConnectionState.waiting) {
                            displayContent = '🔓 Descifrando...';
                          } else if (decryptSnapshot.hasError) {
                            displayContent = '[Error al descifrar]';
                          } else {
                            displayContent = decryptSnapshot.data ?? '[Sin contenido]';
                          }

                          final timestamp = data['timestamp'] as Timestamp?;
                          final senderId = data['senderId'] as String? ?? '';
                          
                          final message = MessageModel(
                            id: doc.id,
                            content: displayContent,
                            timestamp: timestamp?.toDate() ?? DateTime.now(),
                            isUser: senderId == _auth.currentUser!.uid,
                            senderId: senderId,
                            receiverId: data['receiverId'] as String?,
                            isRead: data['isRead'] as bool? ?? false,
                          );

                          return MessageBubble(
                            message: message,
                            isMe: message.isUser,
                            profilePictureUrl: message.isUser 
                                ? _currentUserImageUrl
                                : widget.profilePictureUrl, 
                            isRead: message.isRead,
                          );
                        },
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