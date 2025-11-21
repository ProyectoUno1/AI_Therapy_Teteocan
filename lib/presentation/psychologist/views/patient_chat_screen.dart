// lib/presentation/psychologist/views/patient_chat_screen.dart
// VERSIÓN TOTALMENTE RESPONSIVE

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  bool _isChatEnabled = true;

  @override
  void initState() {
    super.initState();
    // Inicializar IDs y streams
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || !_isChatEnabled) return;
    
    final messageContent = _messageController.text.trim();
    _messageController.clear();
    
    // Enviar mensaje a Firebase
    _scrollToBottom();
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
    // 🎯 Configuración responsive
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;
    
    // Tamaños adaptativos
    final avatarRadius = isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);
    final titleFontSize = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);
    final statusFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildResponsiveAppBar(
        context,
        isMobile: isMobile,
        isTablet: isTablet,
        avatarRadius: avatarRadius,
        titleFontSize: titleFontSize,
        statusFontSize: statusFontSize,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : screenWidth,
            ),
            child: Column(
              children: [
                Expanded(
                  child: _buildResponsiveMessagesList(
                    context,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                ),
                
                if (!_isChatEnabled)
                  _buildChatDisabledBanner(context, isMobile, isTablet),
                
                _buildResponsiveInputBar(
                  context,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required double avatarRadius,
    required double titleFontSize,
    required double statusFontSize,
  }) {
    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      elevation: 1,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          size: isMobile ? 22 : 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.patientImageUrl),
                radius: avatarRadius,
                backgroundColor: AppConstants.lightAccentColor,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: isMobile ? 10 : 12,
                  height: isMobile ? 10 : 12,
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
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'En línea',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: statusFontSize,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!isMobile) ...[
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
            tooltip: 'Videollamada',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'Más opciones',
          ),
        ],
      ],
    );
  }

  Widget _buildResponsiveMessagesList(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
  }) {
    // Mock messages para demostración
    final messages = [
      {'isMe': false, 'text': 'Hola, ¿cómo estás?', 'time': '10:30'},
      {'isMe': true, 'text': 'Muy bien, gracias por preguntar', 'time': '10:31'},
      {'isMe': false, 'text': '¿Podemos agendar una sesión?', 'time': '10:32'},
      {'isMe': true, 'text': 'Por supuesto, te envío disponibilidad', 'time': '10:33'},
    ];

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 20)),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message['isMe'] as bool;
        
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          child: _buildMessageBubble(
            context,
            isMe: isMe,
            text: message['text'] as String,
            time: message['time'] as String,
            isMobile: isMobile,
            isTablet: isTablet,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(
    BuildContext context, {
    required bool isMe,
    required String text,
    required String time,
    required bool isMobile,
    required bool isTablet,
  }) {
    final maxWidth = MediaQuery.of(context).size.width * (isMobile ? 0.75 : 0.65);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : (isTablet ? 14 : 16),
          vertical: isMobile ? 8 : (isTablet ? 10 : 12),
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppConstants.primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: isMobile ? 14 : 15,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: isMobile ? 3 : 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey[500],
                    fontSize: isMobile ? 10 : 11,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: isMobile ? 4 : 6),
                  Icon(
                    Icons.done_all,
                    size: isMobile ? 14 : 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatDisabledBanner(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 10,
      ),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange,
            size: isMobile ? 18 : 20,
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Text(
              'El chat está deshabilitado temporalmente',
              style: TextStyle(
                color: Colors.orange,
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveInputBar(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 8 : (isTablet ? 12 : 16),
        isMobile ? 8 : 12,
        isMobile ? 8 : (isTablet ? 12 : 16),
        isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.attach_file,
              size: isMobile ? 20 : 22,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onPressed: _isChatEnabled ? () {} : null,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: isMobile ? 36 : 40,
              minHeight: isMobile ? 36 : 40,
            ),
          ),
          
          SizedBox(width: isMobile ? 4 : 8),
          
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: isMobile ? 100 : 120,
              ),
              child: TextField(
                controller: _messageController,
                enabled: _isChatEnabled,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: _isChatEnabled
                      ? 'Escribe un mensaje...'
                      : 'Chat deshabilitado',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 8 : 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          SizedBox(width: isMobile ? 4 : 8),
          
          if (!isMobile) ...[
            IconButton(
              icon: Icon(
                Icons.emoji_emotions_outlined,
                size: isMobile ? 20 : 22,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              onPressed: _isChatEnabled ? () {} : null,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isMobile ? 36 : 40,
                minHeight: isMobile ? 36 : 40,
              ),
            ),
            SizedBox(width: isMobile ? 4 : 8),
          ],
          
          Container(
            width: isMobile ? 38 : 42,
            height: isMobile ? 38 : 42,
            decoration: BoxDecoration(
              color: _isChatEnabled
                  ? AppConstants.primaryColor
                  : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: isMobile ? 18 : 20,
              ),
              onPressed: _isChatEnabled ? _sendMessage : null,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: isMobile ? 64 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'Inicia la conversación',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 15 : 16,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              'Envía el primer mensaje a ${widget.patientName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: isMobile ? 12 : 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}