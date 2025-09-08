// lib/presentation/chat/views/chat_list_screen.dart

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/ai_chat_screen.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/psychologist_chat_screen.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_list_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_chat_item.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/presentation/shared/ai_usage_limit_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_state.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_event.dart'; 
import 'package:ai_therapy_teteocan/data/repositories/subscription_repository.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback onGoToPsychologists;
  final String? initialPsychologistId;
  final String? initialChatId;

  const ChatListScreen({
    super.key,
    required this.onGoToPsychologists,
    this.initialPsychologistId,
    this.initialChatId,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  int _usedMessages = 0;
  int _messageLimit = 5;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _startListeningToUserData();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('Error: Usuario no autenticado.'));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ChatListCubit(currentUserId: currentUserId),
        ),
        BlocProvider(
          create: (context) => SubscriptionBloc(
            repository: SubscriptionRepositoryImpl(),
          )..add(LoadSubscriptionStatus()),
        ),
      ],
      child: Scaffold(
        body: BlocListener<SubscriptionBloc, SubscriptionState>(
          listener: (context, state) {
            // Escuchar cambios en el estado de suscripción
            if (state is SubscriptionLoaded) {
              // Actualizar el estado local basado en la suscripción
              setState(() {
                _isPremium = state.hasActiveSubscription;
                _messageLimit = state.hasActiveSubscription ? 9999 : 5;
              });
            }
          },
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // AI Usage Limit Indicator con datos reales
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: AiUsageLimitIndicator(
                    used: _usedMessages,
                    limit: _messageLimit,
                    isPremium: _isPremium,
                  ),
                ),
                Container(
                  color: Theme.of(context).cardColor,
                  child: TabBar(
                    labelColor: AppConstants.lightAccentColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppConstants.lightAccentColor,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology),
                            SizedBox(width: 8),
                            Text(
                              'Aurora AI',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people),
                            SizedBox(width: 8),
                            Text(
                              'Psicólogos',
                              style: TextStyle(fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(
                    children: [_AIChatTabContent(), _PsychologistsChatTabContent()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _AIChatTabContent extends StatelessWidget {
  const _AIChatTabContent();

  @override
  Widget build(BuildContext context) {
   
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildAIChatCard(context),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aurora AI está aquí para ayudarte',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Habla sobre cualquier tema que te preocupe',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Poppins',
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

  Widget _buildAIChatCard(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppConstants.lightAccentColor.withOpacity(0.1),
        child: Icon(Icons.psychology, color: AppConstants.lightAccentColor),
      ),
      title: const Text(
        'Aurora AI',
        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
      ),
      subtitle: const Text(
        'Tu asistente terapéutico 24/7',
        style: TextStyle(fontFamily: 'Poppins'),
      ),
      trailing: Text(
        'Activo',
        style: TextStyle(
          color: AppConstants.lightAccentColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIChatScreen()),
        );
      },
    );
  }
}

class _PsychologistsChatTabContent extends StatelessWidget {
  const _PsychologistsChatTabContent();

  @override
  Widget build(BuildContext context) {
   
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocBuilder<ChatListCubit, ChatListState>(
        builder: (context, state) {
          if (state is ChatListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatListError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ChatListLoaded) {
            if (state.chatRooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay chats activos con psicólogos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Programa una sesión para comenzar a chatear',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      
                      onPressed: () => (context.findAncestorWidgetOfExactType<ChatListScreen>())!.onGoToPsychologists(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.lightAccentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Buscar Psicólogos',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.chatRooms.length,
              itemBuilder: (context, index) {
                final chatItem = state.chatRooms[index];
                
                return _buildPsychologistChatCard(context, chatItem: chatItem);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPsychologistChatCard(
      BuildContext context, {
      required PsychologistChatItem chatItem,
  }) {
    final chatListScreen = context.findAncestorWidgetOfExactType<ChatListScreen>();
    final shouldAutoOpen = chatListScreen?.initialPsychologistId == chatItem.psychologistId;
    
    if (shouldAutoOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PsychologistChatScreen(
              psychologistUid: chatItem.psychologistId,
              psychologistName: chatItem.psychologistName,
              psychologistImageUrl: chatItem.psychologistImageUrl ?? 'https://via.placeholder.com/150',
            ),
          ),
        );
      });
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          chatItem.psychologistImageUrl ?? 'https://via.placeholder.com/150',
        ),
        radius: 24,
      ),
      title: Text(
        chatItem.psychologistName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        chatItem.lastMessage,
        style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        DateFormat('hh:mm a').format(chatItem.lastMessageTime),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PsychologistChatScreen(
              psychologistUid: chatItem.psychologistId,
              psychologistName: chatItem.psychologistName,
              psychologistImageUrl: chatItem.psychologistImageUrl ?? 'https://via.placeholder.com/150',
            ),
          ),
        );
      },
    );
  }
}