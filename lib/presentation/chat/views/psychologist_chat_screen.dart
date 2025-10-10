// lib/presentation/chat/views/psychologist_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:intl/intl.dart';

import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';

class PsychologistChatScreen extends StatefulWidget {
  final String psychologistUid;
  final String psychologistName;
  final String psychologistImageUrl;

  const PsychologistChatScreen({
    super.key,
    required this.psychologistUid,
    required this.psychologistName,
    required this.psychologistImageUrl,
  });

  @override
  State<PsychologistChatScreen> createState() => _PsychologistChatScreenState();
}

class _PsychologistChatScreenState extends State<PsychologistChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late final String _chatId;
  late final ChatRepository _chatRepository;

  late final Stream<DocumentSnapshot> _psychologistStatusStream;

  @override
  void initState() {
    super.initState();
    final currentUserUid = _auth.currentUser!.uid;
    final uids = [currentUserUid, widget.psychologistUid]..sort();
    _chatId = uids.join('_');

    // Inicializa el repositorio
    _chatRepository = ChatRepository();

    _psychologistStatusStream = _firestore
        .collection('users')
        .doc(widget.psychologistUid)
        .snapshots();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    _scrollToBottom();

    try {
      await _chatRepository.sendHumanMessage(
        chatId: _chatId,
        senderId: _auth.currentUser!.uid,
        receiverId: widget.psychologistUid,
        content: messageContent,
        isUser: false,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              backgroundImage: widget.psychologistImageUrl.isNotEmpty
                  ? NetworkImage(widget.psychologistImageUrl)
                        as ImageProvider<Object>
                  : const AssetImage('assets/images/default_avatar.png'),
              radius: 20,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _psychologistStatusStream,
                builder: (context, snapshot) {
                  // Estado por defecto
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
                        lastSeenText =
                            'Última vez visto hace ${difference.inMinutes} min';
                      } else if (difference.inDays < 1) {
                        lastSeenText =
                            'Última vez visto hoy a las ${DateFormat('HH:mm').format(lastSeenDate)}';
                      } else if (difference.inDays < 2) {
                        lastSeenText =
                            'Última vez visto ayer a las ${DateFormat('HH:mm').format(lastSeenDate)}';
                      } else {
                        lastSeenText =
                            'Última vez visto el ${DateFormat('dd MMM').format(lastSeenDate)}';
                      }
                    } else {
                      lastSeenText = 'Última vez visto: N/A';
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.psychologistName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isOnline ? 'En línea' : lastSeenText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOnline
                              ? Colors.green
                              : theme.textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
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
            icon: Icon(Icons.videocam, color: theme.iconTheme.color),
            onPressed: () {
              // Iniciar videollamada
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
            onPressed: () {
              // Mostrar opciones adicionales
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu sesión está programada para hoy a las 15:00',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

                  final messages = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    return MessageModel(
                      id: doc.id,
                      content: data['content'],
                      timestamp: timestamp?.toDate() ?? DateTime.now(),
                      isUser: data['senderId'] == _auth.currentUser!.uid,
                      senderId: data['senderId'] ?? '',
                    );
                  }).toList();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageBubble(
                        message: message,
                        isMe: message.isUser,
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
                    color: theme.iconTheme.color,
                    onPressed: () {
                      // Mostrar opciones de adjuntos
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
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
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: _sendMessage,
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
