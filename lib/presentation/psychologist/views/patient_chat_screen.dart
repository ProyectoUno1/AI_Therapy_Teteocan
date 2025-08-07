// lib/presentation/psychologist/views/patient_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

class PatientChatScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientImageUrl;
  final bool isPatientOnline;

  const PatientChatScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientImageUrl,
    required this.isPatientOnline,
  });

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isPatientTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // TODO: Cargar mensajes reales desde el backend
    setState(() {
      _messages.addAll([
        MessageModel(
          id: '1',
          content: 'Hola doctor, ¿cómo está usted?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isUser: false, // Mensaje del paciente
        ),
        MessageModel(
          id: '2',
          content:
              'Hola ${widget.patientName}, muy bien gracias. ¿Cómo te has sentido desde nuestra última sesión?',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 58),
          ),
          isUser: true, // Mensaje del psicólogo
        ),
        MessageModel(
          id: '3',
          content:
              'He estado practicando los ejercicios de respiración que me enseñó y me han ayudado mucho',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 55),
          ),
          isUser: false,
        ),
        MessageModel(
          id: '4',
          content:
              'Me alegra mucho escuchar eso. Es excelente que hayas sido constante con los ejercicios. ¿Has notado alguna situación específica donde te han funcionado mejor?',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 50),
          ),
          isUser: true,
        ),
      ]);
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = MessageModel(
      id: DateTime.now().toString(),
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      isUser: true, // Mensaje del psicólogo
    );

    setState(() {
      _messages.add(message);
      _messageController.clear();
    });

    _scrollToBottom();

    // TODO: Enviar mensaje al backend
    _simulatePatientResponse();
  }

  void _simulatePatientResponse() {
    // Simular que el paciente está escribiendo
    setState(() {
      _isPatientTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isPatientTyping = false;
        });

        // Simular respuesta del paciente
        final responses = [
          'Gracias doctor, eso me ayuda mucho',
          'Entiendo, voy a intentarlo',
          'Sí, me parece una buena idea',
          'Me siento mejor hablando con usted',
          'Eso tiene mucho sentido',
        ];

        final response = MessageModel(
          id: DateTime.now().toString(),
          content: responses[DateTime.now().millisecond % responses.length],
          timestamp: DateTime.now(),
          isUser: false,
        );

        setState(() {
          _messages.add(response);
        });
        _scrollToBottom();
      }
    });
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
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.patientImageUrl),
                  radius: 20,
                  backgroundColor: AppConstants.lightAccentColor,
                ),
                if (widget.isPatientOnline)
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
                    _isPatientTyping
                        ? 'Escribiendo...'
                        : widget.isPatientOnline
                        ? 'En línea'
                        : 'Última vez hace 2h',
                    style: TextStyle(
                      color: _isPatientTyping || widget.isPatientOnline
                          ? Colors.green
                          : Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontStyle: _isPatientTyping
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam, color: AppConstants.primaryColor),
            onPressed: () {
              _showVideoCallDialog();
            },
          ),
          IconButton(
            icon: Icon(Icons.phone, color: AppConstants.primaryColor),
            onPressed: () {
              _showCallDialog();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showPatientProfile();
                  break;
                case 'notes':
                  _showSessionNotes();
                  break;
                case 'history':
                  _showChatHistory();
                  break;
              }
            },
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
                    Text('Notas de sesión'),
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
          // Mensajes
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isPatientTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isPatientTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MessageBubble(
                          message: _messages[index],
                          isMe: _messages[index]
                              .isUser, // true si es mensaje del psicólogo
                        ),
                      );
                    },
                  ),
          ),

          // Área de entrada de mensaje
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
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[100]
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
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
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppConstants.lightAccentColor,
            backgroundImage: NetworkImage(widget.patientImageUrl),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : Colors.grey[700],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Escribiendo...',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Videollamada'),
        content: Text(
          '¿Deseas iniciar una videollamada con ${widget.patientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar videollamada
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de videollamada próximamente'),
                ),
              );
            },
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamada de voz'),
        content: Text(
          '¿Deseas iniciar una llamada de voz con ${widget.patientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar llamada de voz
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de llamada próximamente'),
                ),
              );
            },
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _showPatientProfile() {
    // TODO: Implementar vista del perfil del paciente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vista de perfil próximamente')),
    );
  }

  void _showSessionNotes() {
    // TODO: Implementar notas de sesión
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notas de sesión próximamente')),
    );
  }

  void _showChatHistory() {
    // TODO: Implementar historial de chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial de chat próximamente')),
    );
  }
}
