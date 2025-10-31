// lib/presentation/psychologist/views/patient_chat_screen.dart
// ✅ VERSIÓN SIN E2EE - SOLO ENCRIPTACIÓN BACKEND

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';

class PatientChatScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientImageUrl;

  const PatientChatScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientImageUrl,
  });

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _currentUserId;
  late String _chatId;
  late final ChatRepository _chatRepository;
  late Stream<DocumentSnapshot> _patientStatusStream;

  bool get _isChatEnabled {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    final status = authState.psychologist?.status;
    return status == 'ACTIVE';
  }

  String _getStatusBasedBlockingMessage() {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    final status = authState.psychologist?.status;

    switch (status) {
      case 'PENDING':
        return 'Tu perfil profesional está en revisión. No podrás chatear con pacientes hasta que sea aprobado.';
      case 'REJECTED':
        return 'Tu perfil profesional fue rechazado. Revisa tu información y reenvía tu solicitud para habilitar el chat.';
      default:
        return 'No puedes acceder al chat hasta que tu perfil profesional esté activo.';
    }
  }

  @override
  void initState() {
    super.initState();
    final authState = BlocProvider.of<AuthBloc>(context).state;
    if (authState.psychologist != null && authState.isAuthenticatedPsychologist) {
      _currentUserId = authState.psychologist!.uid;
      final ids = [_currentUserId!, widget.patientId]..sort();
      _chatId = '${ids[0]}_${ids[1]}';
    }

    _chatRepository = ChatRepository();
    
    _patientStatusStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .snapshots();
    
    print('🔍 Chat ID: $_chatId');
    print('🔍 Current User ID: $_currentUserId');
    print('🔍 Patient ID: ${widget.patientId}');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatRepository.markMessagesAsRead(
        chatId: _chatId,
        currentUserId: _currentUserId!,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;
    if (!_isChatEnabled) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();
    
    print('📤 Enviando mensaje: $messageContent');
    
    try {
      await _chatRepository.sendHumanMessage(
        chatId: _chatId,
        senderId: _currentUserId!,
        receiverId: widget.patientId,
        content: messageContent,
      );
      
      print('✅ Mensaje enviado correctamente');
      _scrollToBottom();
      
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _patientStatusStream,
          builder: (context, snapshot) {
            bool isOnline = false;
            String statusText = 'Cargando...';

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              isOnline = data['isOnline'] ?? false;
              final lastSeenTimestamp = data['lastSeen'] as Timestamp?;
              statusText = isOnline
                  ? 'En línea'
                  : _formatTimestamp(lastSeenTimestamp);
            }

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.patientImageUrl),
                      radius: 20,
                      backgroundColor: AppConstants.lightAccentColor,
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).cardColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
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
                  return _buildEmptyState(context);
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
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MessageBubble(
                        message: message,
                        isMe: message.senderId == _currentUserId,
                        isRead: message.isRead,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          if (!_isChatEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusBasedBlockingMessage(),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.attach_file, 
                      size: 20,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    onPressed: _isChatEnabled ? () {} : null,
                  ),
                  
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _isChatEnabled,
                      decoration: InputDecoration(
                        hintText: _isChatEnabled 
                            ? 'Escribe un mensaje...' 
                            : 'Chat deshabilitado',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isChatEnabled
                          ? AppConstants.primaryColor 
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send, 
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isChatEnabled ? _sendMessage : null,
                      padding: EdgeInsets.zero,
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Desconocido';
    final DateTime lastSeenDate = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeenDate);

    if (difference.inMinutes < 1) {
      return 'hace menos de un minuto';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días';
    } else {
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(lastSeenDate);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Inicia la conversación',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envía el primer mensaje a ${widget.patientName}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}