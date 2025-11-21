// ai_chat_screen.dart - VERSIÓN CORREGIDA CON SUSCRIPCIÓN

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/views/subscription_screen.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_state.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_event.dart';
import 'package:ai_therapy_teteocan/data/repositories/subscription_repository.dart';

// HELPER FUNCTION PARA LIMITAR EL TEXT SCALE FACTOR
double _getConstrainedTextScaleFactor(BuildContext context, {double maxScale = 1.3}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return textScaleFactor.clamp(1.0, maxScale);
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepository = ChatRepository();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isUserScrolling = false;
  
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  int _usedMessages = 0;
  int _messageLimit = 5;
  bool _isPremium = false;

  // Función para obtener tamaño de fuente responsivo
  double _getResponsiveFontSize(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final textScaleFactor = _getConstrainedTextScaleFactor(context);
    
    // Ajustar por orientación
    double scale = isLandscape ? (width / 800) : (width / 375);
    
    // Limitar el escalado para texto grande
    scale = scale.clamp(0.85, 1.2);
    
    // Reducir más en landscape con texto grande
    if (isLandscape && textScaleFactor > 1.2) {
      scale *= 0.85;
    }
    
    return (baseSize * scale).clamp(baseSize * 0.75, baseSize * 1.15);
  }

  // Función para obtener padding responsivo
  EdgeInsets _getResponsivePadding({
    required double horizontal,
    required double vertical,
  }) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final width = MediaQuery.of(context).size.width;
    
    if (isLandscape) {
      return EdgeInsets.symmetric(
        horizontal: width < 600 ? horizontal * 0.75 : horizontal,
        vertical: vertical * 0.6,
      );
    }
    
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollListener);
    _startListeningToUserData();
    _loadMessages();
  }

  void _startListeningToUserData() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _userSubscription = _firestore
          .collection('patients')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          setState(() {
            _usedMessages = data['messageCount'] ?? 0;
            _isPremium = data['isPremium'] == true;
            _messageLimit = _isPremium ? 99999 : 5;
          });
          print('📊 Estado de suscripción actualizado: Premium=$_isPremium, Mensajes usados=$_usedMessages, Límite=$_messageLimit');
        }
      });
    }
  }

  void _onScrollListener() {
    if (_scrollController.position.isScrollingNotifier.value) {
      _isUserScrolling = true;
      
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 100) {
        _isUserScrolling = false;
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScrollListener);
    _scrollController.dispose();
    _userSubscription?.cancel(); 
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('📄 Cargando mensajes desde API...');
      final messages = await _chatRepository.loadAIChatMessages();
      
      print('✅ Mensajes cargados: ${messages.length}');
      for (var msg in messages) {
        print('   💬 "${msg.content}" | isUser: ${msg.isUser} | Timestamp: ${msg.timestamp}');
      }
      
      messages.sort((a, b) {
        final aTime = a.timestamp ?? DateTime(0);
        final bTime = b.timestamp ?? DateTime(0);
        return aTime.compareTo(bTime);
      });
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      _scrollToBottom();
      
    } catch (e) {
      print('❌ Error cargando mensajes: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar mensajes: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    if (!_isPremium && _usedMessages >= _messageLimit) {
      _showLimitReachedDialog();
      return;
    }

    setState(() {
      _isSending = true;
    });

    final userMessage = MessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      isUser: true,
      senderId: 'user',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      print('📤 Enviando mensaje: "$message"');
      final aiResponse = await _chatRepository.sendAIMessage(message);
      
      print('✅ Respuesta IA: "$aiResponse"');
      
      setState(() {
        _messages.removeWhere((msg) => msg.id.startsWith('temp-'));
        
        final userMessageReal = MessageModel(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          content: message,
          isUser: true,
          senderId: 'user',
          timestamp: DateTime.now(),
        );
        
        final aiMessage = MessageModel(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          content: aiResponse,
          isUser: false,
          senderId: 'aurora',
          timestamp: DateTime.now(),
        );
        
        _messages.add(userMessageReal);
        _messages.add(aiMessage);
      });
      
      _scrollToBottom();
      
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      
      setState(() {
        _messages.removeWhere((msg) => msg.id.startsWith('temp-'));
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: _sendMessage,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: _getConstrainedTextScaleFactor(context),
        ),
        child: AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                color: Colors.orange,
                size: _getResponsiveFontSize(24),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Límite Alcanzado',
                  style: TextStyle(fontSize: _getResponsiveFontSize(18)),
                ),
              ),
            ],
          ),
          content: Text(
            '¡Has alcanzado tu límite de mensajes diarios!\n\n'
            'Actualiza a Premium para disfrutar de conversaciones ilimitadas con Aurora AI.',
            style: TextStyle(fontSize: _getResponsiveFontSize(14)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(fontSize: _getResponsiveFontSize(14)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
              child: Text(
                'Actualizar a Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _getResponsiveFontSize(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isUserScrolling) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: _getResponsivePadding(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: _getResponsivePadding(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Aurora está escribiendo...',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(14),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: _getResponsivePadding(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: isLandscape ? 48 : 64,
                color: Colors.grey,
              ),
              SizedBox(height: isLandscape ? 12 : 16),
              Text(
                'Hola! Soy Aurora 🌟',
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLandscape ? 4 : 8),
              Text(
                _isPremium 
                    ? '¡Eres usuario Premium! Disfruta de conversaciones ilimitadas.'
                    : 'Tienes $_messageLimit mensajes disponibles hoy.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: _getResponsiveFontSize(14),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _getResponsivePadding(horizontal: 0, vertical: 16),
      itemCount: messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isSending && index == messages.length) {
          return _buildTypingIndicator();
        }

        if (index < messages.length) {
          final message = messages[index];
          return MessageBubble(
            message: message,
            isMe: message.isUser,
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageInput() {
    final bool isLimitReached = !_isPremium && _usedMessages >= _messageLimit;
    final bool showWarning = !_isPremium && _usedMessages >= _messageLimit - 1;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Container(
      padding: _getResponsivePadding(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showWarning && !_isSending && !isLimitReached)
              Container(
                padding: _getResponsivePadding(horizontal: 12, vertical: 8),
                margin: EdgeInsets.only(
                  bottom: isLandscape ? 4 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: _getResponsiveFontSize(20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Te queda 1 mensaje! Actualiza a Premium para conversaciones ilimitadas.',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(12),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSending && !isLimitReached,
                    decoration: InputDecoration(
                      hintText: isLimitReached
                          ? 'Límite de mensajes alcanzado'
                          : _isSending 
                              ? 'Aurora está pensando...' 
                              : 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                        color: isLimitReached 
                            ? Colors.red.shade400
                            : _isSending 
                                ? Colors.grey.shade400 
                                : Colors.grey,
                        fontFamily: 'Poppins',
                        fontSize: _getResponsiveFontSize(14),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isLimitReached
                          ? Colors.red.shade50
                          : _isSending 
                              ? Colors.grey[200] 
                              : Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_isSending || isLimitReached) ? null : (_) => _sendMessage(),
                    maxLines: isLandscape ? 2 : 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: _getResponsiveFontSize(14)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (_isSending || isLimitReached)
                        ? Colors.grey 
                        : AppConstants.lightAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 24,
                    padding: EdgeInsets.zero,
                    icon: _isSending 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            isLimitReached ? Icons.lock : Icons.send_rounded,
                            color: Colors.white,
                          ),
                    onPressed: (_isSending || isLimitReached) ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPrompt(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return SingleChildScrollView(
      child: Container(
        padding: _getResponsivePadding(horizontal: 16, vertical: 16),
        margin: _getResponsivePadding(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: isLandscape ? 36 : 48,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: isLandscape ? 8 : 12),
            Text(
              '¡Has usado $_usedMessages de $_messageLimit mensajes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isLandscape ? 4 : 8),
            Text(
              'Actualiza tu plan a Premium para disfrutar de conversaciones ilimitadas con Aurora AI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(14),
                color: Colors.grey,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isLandscape ? 12 : 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              icon: Icon(
                Icons.workspace_premium_outlined,
                color: Colors.white,
                size: _getResponsiveFontSize(20),
              ),
              label: Text(
                'Actualizar a Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveFontSize(16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.08,
                  vertical: 12,
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLimitReached = !_isPremium && _usedMessages >= _messageLimit;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          toolbarHeight: isLandscape ? 48 : 56,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            iconSize: _getResponsiveFontSize(24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: isLandscape ? 14 : 20,
                backgroundColor: AppConstants.lightAccentColor,
                child: Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: isLandscape ? 16 : 20,
                ),
              ),
              SizedBox(width: isLandscape ? 8 : 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Aurora AI',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: _getResponsiveFontSize(16),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _isPremium ? 'Premium - Ilimitado' : 'Gratis - $_usedMessages/$_messageLimit',
                      style: TextStyle(
                        color: _isPremium ? Colors.green : Colors.grey,
                        fontSize: _getResponsiveFontSize(12),
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              iconSize: _getResponsiveFontSize(24),
              onPressed: _loadMessages,
              tooltip: 'Recargar mensajes',
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[700]),
              iconSize: _getResponsiveFontSize(24),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isLoading && _messages.isEmpty)
              const LinearProgressIndicator(),
              
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: _isLoading && _messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(_messages),
              ),
            ),
            
            isLimitReached 
                ? _buildSubscriptionPrompt(context)
                : _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}