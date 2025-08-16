// lib/presentation/chat/views/psychologist_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:intl/intl.dart'; 

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

  
  late final Stream<DocumentSnapshot> _psychologistStatusStream;

  @override
  void initState() {
    super.initState();
    final currentUserUid = _auth.currentUser!.uid;
    final uids = [currentUserUid, widget.psychologistUid]..sort();
    _chatId = uids.join('_');

    
    _psychologistStatusStream = _firestore.collection('users').doc(widget.psychologistUid).snapshots();
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

    final currentUserUid = _auth.currentUser!.uid;

    //  Paso 1: Guarda el mensaje en la subcolección de mensajes.
    final messageDocRef = _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .doc();

    await messageDocRef.set({
      'senderId': currentUserUid,
      'content': messageContent,
      'timestamp': FieldValue.serverTimestamp(),
    });

    //  Paso 2: Actualiza el documento de resumen en la colección 'chats'.
    await _firestore.collection('chats').doc(_chatId).set(
      {
        'participants': [currentUserUid, widget.psychologistUid],
        'lastMessage': messageContent,
        'lastTimestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    _scrollToBottom();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.psychologistImageUrl),
              radius: 20,
            ),
            const SizedBox(width: 12),
            
            StreamBuilder<DocumentSnapshot>(
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
                      lastSeenText = 'Última vez visto hace ${difference.inMinutes} min';
                    } else if (difference.inDays < 1) {
                      lastSeenText = 'Última vez visto hoy a las ${DateFormat('HH:mm').format(lastSeenDate)}';
                    } else if (difference.inDays < 2) {
                      lastSeenText = 'Última vez visto ayer a las ${DateFormat('HH:mm').format(lastSeenDate)}';
                    } else {
                      lastSeenText = 'Última vez visto el ${DateFormat('dd MMM').format(lastSeenDate)}';
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
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      isOnline ? 'En línea' : lastSeenText,
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black87),
            onPressed: () {
              // Iniciar videollamada
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
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
            color: AppConstants.lightAccentColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppConstants.lightAccentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu sesión está programada para hoy a las 15:00',
                    style: TextStyle(
                      color: AppConstants.lightAccentColor,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[50],
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
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: Colors.grey[600],
                    onPressed: () {
                      // Mostrar opciones de adjuntos
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
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
                      color: AppConstants.lightAccentColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
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