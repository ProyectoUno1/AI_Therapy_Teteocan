// ai_chat_screen.dart (CON TRACKING DE LÍMITES EN TIEMPO REAL)
import 'dart:async'; // Añadir para StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/chat/widgets/message_bubble.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_event.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_state.dart';
import 'package:ai_therapy_teteocan/data/models/message_model.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_state.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/ai_usage_limit_indicator.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/views/subscription_screen.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Variables para controlar el auto-scroll
  bool _isUserScrolling = false;
  int _previousMessageCount = 0;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  int _usedMessages = 0;
  int _messageLimit = 5;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScrollListener);

    _startListeningToUserData();

    // Inicializar el chat
    final authState = context.read<AuthBloc>().state;
    if (authState.isAuthenticatedPatient) {
      final userId = authState.patient!.uid;
      context.read<ChatBloc>().add(InitAIChat(userId));
    }
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
                // Si es premium, límite muy alto, sino 5 mensajes
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

      if (_scrollController.offset <=
          _scrollController.position.minScrollExtent + 100) {
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    if (!_isPremium && _usedMessages >= _messageLimit) {
      // Mostrar mensaje de límite alcanzado
      _showLimitReachedDialog();
      return;
    }

    context.read<ChatBloc>().add(
      SendMessageEvent(_messageController.text.trim(), _auth.currentUser!.uid),
    );

    _messageController.clear();
    _isUserScrolling = false;
    _scrollToBottom();
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
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
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
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _autoScrollOnNewMessage(int currentMessageCount) {
    if (currentMessageCount > _previousMessageCount && !_isUserScrolling) {
      _scrollToBottom();
    }
    _previousMessageCount = currentMessageCount;
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
              const Text('Aurora está escribiendo'),
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

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Usuario no autenticado')),
      );
    }

    final messagesStream = _firestore
        .collection('ai_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

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
              child: Icon(Icons.psychology, color: Colors.white),
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
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            onPressed: () {
              // Opciones adicionales
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: BlocListener<ChatBloc, ChatState>(
                listenWhen: (previous, current) {
                  return previous.isTyping != current.isTyping;
                },
                listener: (context, state) {
                  if (!state.isTyping) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _scrollToBottom();
                    });
                  }
                },
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        final messages = snapshot.data!.docs.map((doc) {
                          return MessageModel.fromFirestore(doc, userId);
                        }).toList();

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _autoScrollOnNewMessage(messages.length);
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: messages.length + (state.isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (state.isTyping && index == 0) {
                              return _buildTypingIndicator();
                            }

                            final messageIndex = state.isTyping
                                ? index - 1
                                : index;

                            if (messageIndex >= 0 &&
                                messageIndex < messages.length) {
                              final message = messages[messageIndex];
                              return MessageBubble(
                                message: message,
                                isMe: message.isUser,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (isLimitReached || state.isMessageLimitReached) {
                return _buildSubscriptionPrompt(context);
              } else {
                return _buildMessageInput(context, state.isLoading);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, bool isLoading) {
    // Determinar si mostrar límite alcanzado basado en datos locales
    final bool isLimitReached = !_isPremium && _usedMessages >= _messageLimit;

    // Mostrar progreso hacia el límite si no es premium
    final bool showWarning = !_isPremium && _usedMessages >= _messageLimit - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Mostrar advertencia cuando queda 1 mensaje
            if (showWarning && !isLoading && !isLimitReached)
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
                    enabled: !isLoading && !isLimitReached,
                    decoration: InputDecoration(
                      hintText: isLimitReached
                          ? 'Límite de mensajes alcanzado'
                          : isLoading
                          ? 'Aurora está pensando...'
                          : 'Escribe un mensaje...',
                      hintStyle: TextStyle(
                        color: isLimitReached
                            ? Colors.red.shade400
                            : isLoading
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
                          : isLoading
                          ? Colors.grey[200]
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (isLoading || isLimitReached)
                        ? null
                        : (_) => _sendMessage(),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: (isLoading || isLimitReached)
                        ? Colors.grey
                        : AppConstants.lightAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isLimitReached ? Icons.lock : Icons.send_rounded,
                            color: Colors.white,
                          ),
                    onPressed: (isLoading || isLimitReached)
                        ? null
                        : _sendMessage,
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
          Icon(Icons.lock_outline, size: 48, color: AppConstants.primaryColor),
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
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
}
