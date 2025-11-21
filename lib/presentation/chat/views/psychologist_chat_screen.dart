// lib/presentation/chat/views/psychologist_chat_screen.dart
// ✅ VERSIÓN RESPONSIVA CON ADAPTACIÓN DE FUENTES

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';

// HELPER FUNCTION PARA LIMITAR EL TEXT SCALE FACTOR
double _getConstrainedTextScaleFactor(BuildContext context, {double maxScale = 1.3}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return textScaleFactor.clamp(1.0, maxScale);
}

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
  
  late String _currentUserId;
  late final String _chatId;
  late final ChatRepository _chatRepository;
  late final Stream<DocumentSnapshot> _psychologistStatusStream;
  
  String? _currentUserImageUrl;

  @override
  void initState() {
    super.initState();
    
    _currentUserId = _auth.currentUser!.uid;
    
    final uids = [_currentUserId, widget.psychologistUid]..sort();
    _chatId = uids.join('_');

    _chatRepository = ChatRepository();

    _psychologistStatusStream = _firestore
        .collection('users')
        .doc(widget.psychologistUid)
        .snapshots();
    
    _loadCurrentUserImage();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatRepository.markMessagesAsRead(
        chatId: _chatId,
        currentUserId: _currentUserId,
      );
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatRepository.sendHumanMessage(
        chatId: _chatId,
        senderId: _currentUserId,
        receiverId: widget.psychologistUid,
        content: messageContent,
      );
      
      _scrollToBottom();
    } catch (e) {
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context),
      ),
      child: _buildChatScreen(context),
    );
  }

  Widget _buildChatScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenHeight < 400;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        toolbarHeight: isLandscape || isVerySmallScreen ? 48 : 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          iconSize: isLandscape ? 20 : 24,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.profilePictureUrl.isNotEmpty
                  ? NetworkImage(widget.profilePictureUrl)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              radius: isLandscape ? 14 : 20,
            ),
            SizedBox(width: isLandscape ? 8 : 12),
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
                          fontSize: isLandscape ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isOnline ? 'En línea' : lastSeenText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOnline ? Colors.green : theme.textTheme.bodySmall?.color,
                          fontSize: isLandscape ? 10 : 12,
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
                    return _buildEmptyState(isLandscape);
                  }

                  final messages = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return MessageModel(
                      id: doc.id,
                      content: data['content'] ?? '',
                      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      isUser: data['senderId'] == _currentUserId,
                      senderId: data['senderId'] ?? '',
                      receiverId: data['receiverId'] as String?,
                      isRead: data['isRead'] as bool? ?? false,
                    );
                  }).toList();

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: isLandscape ? 8 : 16,
                      bottom: isLandscape ? 8 : 16,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLandscape ? 4 : 8),
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
          _buildMessageInput(theme, isLandscape, isVerySmallScreen),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLandscape) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: isLandscape ? 48 : 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: isLandscape ? 12 : 16),
          Text(
            'Inicia una conversación...',
            style: TextStyle(
              fontSize: isLandscape ? 14 : 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme, bool isLandscape, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 12 : 16,
        vertical: isLandscape || isVerySmallScreen ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isLandscape)
              IconButton(
                icon: const Icon(Icons.attach_file),
                color: Colors.grey[600],
                iconSize: isLandscape ? 20 : 24,
                onPressed: () {},
              ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isLandscape ? 12 : 14,
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 16 : 20,
                    vertical: isLandscape ? 8 : 10,
                  ),
                  isDense: isLandscape,
                ),
                style: TextStyle(fontSize: isLandscape ? 12 : 14),
                onSubmitted: (_) => _sendMessage(),
                maxLines: isLandscape ? 1 : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: isLandscape || isVerySmallScreen ? 40 : 48,
              height: isLandscape || isVerySmallScreen ? 40 : 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: isLandscape ? 20 : 24,
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
    );
  }
}