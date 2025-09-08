// lib/presentation/psychologist/views/patient_chat_screen.dart
// vista del psicólogo

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_state.dart';
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
  bool get _isProfessionalLicenseVerified {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    final license = authState.psychologist?.professionalLicense;
    return license != null && license.trim().isNotEmpty;
  }

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  late String _chatId;
  late Stream<DocumentSnapshot> _patientStatusStream;
  late final ChatRepository _chatRepository;

  // Función para verificar si la licencia profesional está verificada
  bool get _isProfessionalLicenseVerified {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    final license = authState.psychologist?.professionalLicense;
    return license != null && license.trim().isNotEmpty;
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

  BlocProvider.of<PsychologistChatBloc>(context).add(
    LoadChatMessages(
      _chatId,
      _currentUserId!,
    ),
  );
  
  _patientStatusStream = FirebaseFirestore.instance
      .collection('users')
      .doc(widget.patientId)
      .snapshots();
}

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;
    if (!_isProfessionalLicenseVerified) return; // No enviar si no está verificado

    final messageContent = _messageController.text.trim();
    _messageController.clear();
    
    _scrollToBottom();


  
    try {
      await _chatRepository.sendHumanMessage(
        chatId: _chatId,
        senderId: _currentUserId!,
        receiverId: widget.patientId,
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
                ? 'En l\u00ednea'
                : 'Última vez: ${_formatTimestamp(lastSeenTimestamp)}';
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
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam, color: AppConstants.primaryColor),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.phone, color: AppConstants.primaryColor),
          onPressed: () {},
        ),
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
            const PopupMenuItem(
              value: 'notes',
              child: Row(
                children: [
                  Icon(Icons.note),
                  SizedBox(width: 8),
                  Text('Notas de sesi\u00f3n'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('Historial'),
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
          child: BlocConsumer<PsychologistChatBloc, PsychologistChatState>(
            listener: (context, state) {
              if (state is PsychologistChatLoaded) {
                _scrollToBottom();
              }
            },
            builder: (context, state) {
              if (state is PsychologistChatLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is PsychologistChatError) {
                return Center(child: Text(state.message));
              }
              if (state is PsychologistChatLoaded) {
                if (state.messages.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == _currentUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MessageBubble(
                        message: message,
                        isMe: isMe,
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        
        // Aviso de licencia no verificada
        if (!_isProfessionalLicenseVerified)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Debes autenticar tu cédula profesional para poder interactuar con pacientes en el chat.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[100]
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    enabled: _isProfessionalLicenseVerified,
                    decoration: InputDecoration(
                      hintText: _isProfessionalLicenseVerified
                          ? 'Escribe un mensaje...'
                          : 'Debes autenticar tu cédula profesional para chatear',
                      hintStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontFamily: 'Poppins',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _isProfessionalLicenseVerified
                      ? AppConstants.primaryColor
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isProfessionalLicenseVerified ? _sendMessage : null,
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
