// ai_chat_screen.dart - VERSIÓN CORREGIDA
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
            _messageLimit = data['isPremium'] == true ? 99999 : 5;
            _isPremium = data['isPremium'] == true;
          });
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
      print('🔄 Cargando mensajes desde API...');
      final messages = await _chatRepository.loadAIChatMessages();
      
      print('✅ Mensajes cargados: ${messages.length}');
      for (var msg in messages) {
        print('   💬 "${msg.content}" | isUser: ${msg.isUser} | Timestamp: ${msg.timestamp}');
      }
      
      // ✅ CORREGIDO: Ordenar mensajes por timestamp (más antiguo primero)
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mensajes: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // Verificar límite de mensajes
    if (!_isPremium && _usedMessages >= _messageLimit) {
      _showLimitReachedDialog();
      return;
    }

    setState(() {
      _isSending = true;
    });

    // Agregar mensaje usuario localmente
    final userMessage = MessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      isUser: true,
      senderId: 'user',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage); // Se agrega al final (más reciente)
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      print('📤 Enviando mensaje: "$message"');
      final aiResponse = await _chatRepository.sendAIMessage(message);
      
      print('✅ Respuesta IA: "$aiResponse"');
      
      // Remover mensaje temporal y agregar mensajes reales
      setState(() {
        _messages.removeWhere((msg) => msg.id.startsWith('temp-'));
        
        // Agregar mensaje usuario confirmado
        final userMessageReal = MessageModel(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          content: message,
          isUser: true,
          senderId: 'user',
          timestamp: DateTime.now(),
        );
        
        // Agregar respuesta IA
        final aiMessage = MessageModel(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          content: aiResponse,
          isUser: false,
          senderId: 'aurora',
          timestamp: DateTime.now(),
        );
        
        // ✅ CORREGIDO: Agregar en orden cronológico (al final)
        _messages.add(userMessageReal);
        _messages.add(aiMessage);
      });
      
      _scrollToBottom();
      
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
      
      // Remover mensaje temporal si falló
      setState(() {
        _messages.removeWhere((msg) => msg.id.startsWith('temp-'));
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar mensaje: $e'),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _sendMessage,
          ),
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Límite Alcanzado'),
          ],
        ),
        content: const Text(
          '¡Has alcanzado tu límite de mensajes diarios!\n\n'
          'Actualiza a Premium para disfrutar de conversaciones ilimitadas con Aurora AI.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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
            child: const Text(
              'Actualizar a Premium',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isUserScrolling) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // ✅ Ir al final (mensaje más reciente)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
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
              const Text('Aurora está escribiendo...'),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Hola! Soy Aurora 🌟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Inicia la conversación para comenzar',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      reverse: false, // ✅ NO invertir - orden natural
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        // Si está enviando, mostrar indicador al FINAL de la lista
        if (_isSending && index == messages.length) {
          return _buildTypingIndicator();
        }

        // Mensajes normales en orden cronológico
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Mostrar advertencia cuando queda 1 mensaje
            if (showWarning && !_isSending && !isLimitReached)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '¡Te queda 1 mensaje! Actualiza a Premium para conversaciones ilimitadas.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_isSending || isLimitReached) ? null : (_) => _sendMessage(),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: (_isSending || isLimitReached)
                        ? Colors.grey 
                        : AppConstants.lightAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
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
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            '¡Has usado $_usedMessages de $_messageLimit mensajes!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Actualiza tu plan a Premium para disfrutar de conversaciones ilimitadas con Aurora AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.workspace_premium_outlined,
              color: Colors.white,
            ),
            label: const Text(
              'Actualizar a Premium',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLimitReached = !_isPremium && _usedMessages >= _messageLimit;

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
              backgroundColor: AppConstants.lightAccentColor,
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aurora AI',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Siempre disponible',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadMessages,
            tooltip: 'Recargar mensajes',
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            onPressed: () {
              // Opciones adicionales
            },
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
    );
  }
}