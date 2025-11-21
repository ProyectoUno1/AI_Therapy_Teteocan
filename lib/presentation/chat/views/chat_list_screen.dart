// chat_list_screen.dart - VERSIÓN CORREGIDA CON SUSCRIPCIÓN

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
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

// HELPER FUNCTION PARA LIMITAR EL TEXT SCALE FACTOR
double _getConstrainedTextScaleFactor(
  BuildContext context, {
  double maxScale = 1.3,
}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return textScaleFactor.clamp(1.0, maxScale);
}

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
              if (mounted) {
                setState(() {
                  _usedMessages = data['messageCount'] ?? 0;
                  _isPremium = data['isPremium'] == true;
                  _messageLimit = _isPremium ? 99999 : 5;
                });
                print('📊 ChatList - Estado de suscripción: Premium=$_isPremium, Mensajes=$_usedMessages/$_messageLimit');
              }
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;

    if (currentUserId == null) {
      return const Center(child: Text('Error: Usuario no autenticado.'));
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context, maxScale: 1.1),
      ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ChatListCubit(currentUserId: currentUserId),
          ),
        ],
        child: Scaffold(
          body: _ChatListContent(
            onGoToPsychologists: widget.onGoToPsychologists,
            initialPsychologistId: widget.initialPsychologistId,
            isLandscape: isLandscape,
            screenHeight: screenHeight,
            usedMessages: _usedMessages,
            messageLimit: _messageLimit,
            isPremium: _isPremium,
          ),
        ),
      ),
    );
  }
}

class _ChatListContent extends StatelessWidget {
  final VoidCallback onGoToPsychologists;
  final String? initialPsychologistId;
  final bool isLandscape;
  final double screenHeight;
  final int usedMessages;
  final int messageLimit;
  final bool isPremium;

  const _ChatListContent({
    required this.onGoToPsychologists,
    required this.initialPsychologistId,
    required this.isLandscape,
    required this.screenHeight,
    required this.usedMessages,
    required this.messageLimit,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = screenHeight < 500;
    final isVerySmallScreen = screenHeight < 400;

    final double tabBarHeight = isLandscape
        ? 48.0
        : (isVerySmallScreen ? 32.0 : (isSmallScreen ? 40.0 : 48.0));
    final double titleFontSize = isLandscape
        ? 14.0
        : (isVerySmallScreen ? 10.0 : (isSmallScreen ? 12.0 : 14.0));
    final compactMode = isLandscape || isSmallScreen;

    if (isLandscape) {
      return _buildLandscapeLayout(
        context,
        compactMode,
        tabBarHeight,
        titleFontSize,
      );
    } else {
      return _buildPortraitLayout(
        context,
        compactMode,
        tabBarHeight,
        titleFontSize,
      );
    }
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    bool compactMode,
    double tabBarHeight,
    double titleFontSize,
  ) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 80.0,
                floating: true,
                snap: true,
                pinned: true,
                backgroundColor: Theme.of(context).cardColor,
                elevation: 2.0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20.0,
                              backgroundColor: AppConstants.lightAccentColor
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 20.0,
                                color: AppConstants.lightAccentColor,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aurora AI',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    isPremium ? 'Premium - Ilimitado' : 'Gratis - $usedMessages/$messageLimit',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: isPremium ? Colors.green : Colors.grey[600],
                                      fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 6.0,
                              ),
                              decoration: BoxDecoration(
                                color: isPremium 
                                    ? Colors.green.withOpacity(0.1)
                                    : AppConstants.lightAccentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Text(
                                isPremium ? 'Premium' : 'Gratis',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w600,
                                  color: isPremium ? Colors.green : AppConstants.lightAccentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        AiUsageLimitIndicator(
                          used: usedMessages,
                          limit: messageLimit,
                          isPremium: isPremium,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(tabBarHeight),
                  child: Container(
                    color: Theme.of(context).cardColor,
                    child: TabBar(
                      labelColor: AppConstants.lightAccentColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppConstants.lightAccentColor,
                      tabs: [
                        Tab(
                          child: Text(
                            'Aurora AI',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Psicólogos',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _AIChatTabContent(
                compact: compactMode, 
                isLandscape: true,
                isPremium: isPremium,
                usedMessages: usedMessages,
                messageLimit: messageLimit,
              ),
              _PsychologistsChatTabContent(
                onGoToPsychologists: onGoToPsychologists,
                initialPsychologistId: initialPsychologistId,
                compact: compactMode,
                isLandscape: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    bool compactMode,
    double tabBarHeight,
    double titleFontSize,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header fijo para portrait
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24.0,
                      backgroundColor: AppConstants.lightAccentColor
                          .withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 24.0,
                        color: AppConstants.lightAccentColor,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aurora AI',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            isPremium ? 'Premium - Ilimitado' : 'Gratis - $usedMessages/$messageLimit',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: isPremium ? Colors.green : Colors.grey[600],
                              fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: isPremium 
                            ? Colors.green.withOpacity(0.1)
                            : AppConstants.lightAccentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        isPremium ? 'Premium' : 'Gratis',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: isPremium ? Colors.green : AppConstants.lightAccentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!compactMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: AiUsageLimitIndicator(
                      used: usedMessages,
                      limit: messageLimit,
                      isPremium: isPremium,
                      compact: compactMode,
                    ),
                  ),
              ],
            ),
          ),

          // TabBar
          Container(
            height: tabBarHeight,
            color: Theme.of(context).cardColor,
            child: TabBar(
              labelColor: AppConstants.lightAccentColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppConstants.lightAccentColor,
              tabs: [
                Tab(
                  child: Text(
                    'Aurora AI',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    'Psicólogos',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: TabBarView(
              children: [
                _AIChatTabContent(
                  compact: compactMode, 
                  isLandscape: false,
                  isPremium: isPremium,
                  usedMessages: usedMessages,
                  messageLimit: messageLimit,
                ),
                _PsychologistsChatTabContent(
                  onGoToPsychologists: onGoToPsychologists,
                  initialPsychologistId: initialPsychologistId,
                  compact: compactMode,
                  isLandscape: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AIChatTabContent extends StatelessWidget {
  final bool compact;
  final bool isLandscape;
  final bool isPremium;
  final int usedMessages;
  final int messageLimit;

  const _AIChatTabContent({
    required this.compact,
    required this.isLandscape,
    required this.isPremium,
    required this.usedMessages,
    required this.messageLimit,
  });

  @override
  Widget build(BuildContext context) {
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            children: [
              // Tarjeta de Aurora AI
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 16.0 : 16.0,
                  vertical: isLandscape ? 12.0 : 8.0,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 16.0 : 16.0,
                      vertical: isLandscape ? 12.0 : 12.0,
                    ),
                    leading: CircleAvatar(
                      radius: isLandscape ? 24.0 : 24.0,
                      backgroundColor: AppConstants.lightAccentColor
                          .withOpacity(0.1),
                      child: Icon(
                        Icons.psychology,
                        size: isLandscape ? 24.0 : 24.0,
                        color: AppConstants.lightAccentColor,
                      ),
                    ),
                    title: Text(
                      'Aurora AI',
                      style: TextStyle(
                        fontSize: (compact ? 16.0 : 18.0) * textScaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      isPremium 
                          ? 'Premium - Conversaciones ilimitadas'
                          : 'Gratis - $usedMessages/$messageLimit mensajes',
                      style: TextStyle(
                        fontSize: (compact ? 14.0 : 16.0) * textScaleFactor,
                        color: isPremium ? Colors.green : Colors.grey,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPremium 
                            ? Colors.green.withOpacity(0.1)
                            : AppConstants.lightAccentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPremium ? 'Premium' : 'Activo',
                        style: TextStyle(
                          fontSize: (compact ? 12.0 : 14.0) * textScaleFactor,
                          fontWeight: FontWeight.w600,
                          color: isPremium ? Colors.green : AppConstants.lightAccentColor,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AIChatScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const Divider(height: 1),

              // Contenido informativo
              Container(
                padding: EdgeInsets.all(isLandscape ? 24.0 : 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: compact ? 80.0 : 100.0,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: compact ? 16.0 : 20.0),
                    Text(
                      'Aurora AI está aquí para ayudarte',
                      style: TextStyle(
                        fontSize: (compact ? 18.0 : 22.0) * textScaleFactor,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: compact ? 8.0 : 12.0),
                    Text(
                      isPremium
                          ? '¡Disfruta de conversaciones ilimitadas!'
                          : 'Tienes $messageLimit mensajes disponibles hoy.',
                      style: TextStyle(
                        fontSize: (compact ? 16.0 : 18.0) * textScaleFactor,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: compact ? 24.0 : 32.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AIChatScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.lightAccentColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 16.0 : 18.0,
                            horizontal: 16.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            'Comenzar Chat con Aurora AI',
                            style: TextStyle(
                              fontSize: (compact ? 16.0 : 18.0) * textScaleFactor,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 40.0 : 20.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _PsychologistsChatTabContent extends StatelessWidget {
  final VoidCallback onGoToPsychologists;
  final String? initialPsychologistId;
  final bool compact;
  final bool isLandscape;

  const _PsychologistsChatTabContent({
    required this.onGoToPsychologists,
    this.initialPsychologistId,
    required this.compact,
    required this.isLandscape,
  });

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
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _buildErrorState(context, state.message),
            );
          }

          if (state is ChatListLoaded) {
            if (state.chatRooms.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildEmptyState(context),
              );
            }

            return _buildChatList(context, state.chatRooms);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: compact ? 48.0 : 64.0,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar chats',
            style: TextStyle(
              fontSize: (compact ? 16.0 : 20.0) * textScaleFactor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: (compact ? 14.0 : 16.0) * textScaleFactor,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isLandscape ? 40.0 : 20.0),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outlined,
            size: compact ? 60.0 : 80.0,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay chats activos con psicólogos',
            style: TextStyle(
              fontSize: (compact ? 16.0 : 20.0) * textScaleFactor,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Programa una sesión para comenzar a chatear',
            style: TextStyle(
              fontSize: (compact ? 14.0 : 16.0) * textScaleFactor,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: isLandscape ? 200.0 : double.infinity,
            child: ElevatedButton(
              onPressed: onGoToPsychologists,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.lightAccentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: compact ? 12.0 : 16.0),
              ),
              child: Text(
                'Buscar Psicólogos',
                style: TextStyle(
                  fontSize: (compact ? 14.0 : 16.0) * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: isLandscape ? 40.0 : 20.0),
        ],
      ),
    );
  }

  Widget _buildChatList(
    BuildContext context,
    List<PsychologistChatItem> chatRooms,
  ) {
    if (initialPsychologistId != null) {
      final initialChat = chatRooms.firstWhere(
        (chat) => chat.psychologistId == initialPsychologistId,
        orElse: () => chatRooms.first,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PsychologistChatScreen(
              psychologistUid: initialChat.psychologistId,
              psychologistName: initialChat.psychologistName,
              profilePictureUrl:
                  initialChat.profilePictureUrl ??
                  'https://via.placeholder.com/150',
            ),
          ),
        );
      });
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: isLandscape ? 4.0 : 8.0),
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatItem = chatRooms[index];
        return _buildChatCard(context, chatItem);
      },
    );
  }

  Widget _buildChatCard(BuildContext context, PsychologistChatItem chatItem) {
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isLandscape ? 8.0 : 12.0,
        vertical: isLandscape ? 2.0 : 4.0,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: compact,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 12.0 : 16.0,
          vertical: isLandscape ? 6.0 : 8.0,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: isLandscape ? 18.0 : 22.0,
              backgroundImage: NetworkImage(
                chatItem.profilePictureUrl ?? 'https://via.placeholder.com/150',
              ),
            ),
            if (chatItem.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: isLandscape ? 8.0 : 10.0,
                  height: isLandscape ? 8.0 : 10.0,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chatItem.psychologistName,
          style: TextStyle(
            fontSize: (compact ? 12.0 : 14.0) * textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          chatItem.isTyping ? 'Escribiendo...' : chatItem.lastMessage,
          style: TextStyle(
            fontSize: (compact ? 10.0 : 12.0) * textScaleFactor,
            color: chatItem.isTyping
                ? AppConstants.lightAccentColor
                : Colors.grey[600],
            fontStyle: chatItem.isTyping ? FontStyle.italic : FontStyle.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: isLandscape ? 40.0 : 50.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(chatItem.lastMessageTime),
                style: TextStyle(
                  fontSize: (compact ? 9.0 : 10.0) * textScaleFactor,
                  color: Colors.grey[400],
                ),
              ),
              if (chatItem.unreadCount > 0) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppConstants.lightAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${chatItem.unreadCount}',
                    style: TextStyle(
                      fontSize: (compact ? 8.0 : 9.0) * textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PsychologistChatScreen(
                psychologistUid: chatItem.psychologistId,
                psychologistName: chatItem.psychologistName,
                profilePictureUrl:
                    chatItem.profilePictureUrl ??
                    'https://via.placeholder.com/150',
              ),
            ),
          );
        },
      ),
    );
  }
}
