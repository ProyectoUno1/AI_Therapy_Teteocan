// lib/presentation/psychologist/views/patient_chat_screen.dart
// ✅ VERSIÓN CON E2EE CORREGIDA

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
import 'package:ai_therapy_teteocan/core/services/e2ee_service.dart';

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
  final _e2eeService = E2EEService(); // ✅ Agregar servicio E2EE
  
  String? _currentUserId;
  late String _chatId;
  late Stream<DocumentSnapshot> _patientStatusStream;
  late final ChatRepository _chatRepository;
  
  bool _isInitialized = false;

  bool get _isChatEnabled {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    final status = authState.psychologist?.status;
    return status == 'ACTIVE' && _isInitialized;
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
    
    _initializeE2EE();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatRepository.markMessagesAsRead(
        chatId: _chatId,
        currentUserId: _currentUserId!,
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
    
    _scrollToBottom();

    try {
      await _chatRepository.sendHumanMessage(
        chatId: _chatId,
        senderId: _currentUserId!,
        receiverId: widget.patientId,
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

      if (isE2EE && content.startsWith('{') && content.contains('encryptedMessage')) {
        return await _e2eeService.decryptMessage(content);
      }
      
      return content;
    } catch (e) {
      print('⚠️ Error descifrando: $e');
      return '[Mensaje cifrado - Error al descifrar]';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Mostrar indicador si E2EE no está listo
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.patientName)),
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
                      Row(
                        children: [
                          // ✅ Indicador de cifrado
                          const Icon(Icons.lock, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: isOnline ? Colors.green : Colors.grey,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Ver perfil'),
                  ],
                ),
              ),
            ],
          ),
        ],
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

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
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
                          isUser: senderId == _currentUserId,
                          senderId: senderId,
                          receiverId: data['receiverId'] as String?,
                          isRead: data['isRead'] as bool? ?? false,
                        );

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
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.attach_file, 
                    size: 20,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  onPressed: _isChatEnabled ? () {} : null,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
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