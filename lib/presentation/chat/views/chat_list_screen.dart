import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/ai_chat_screen.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/psychologist_chat_screen.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_list_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_chat_item.dart';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/presentation/shared/widgets/ai_usage_limit_indicator.dart';

class ChatListScreen extends StatelessWidget {
  final VoidCallback onGoToPsychologists;

  const ChatListScreen({super.key, required this.onGoToPsychologists});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('Error: Usuario no autenticado.'));
    }

    return BlocProvider(
      create: (context) => ChatListCubit(currentUserId: currentUserId),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // AI Usage Limit Indicator (hardcoded for now, replace with real values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: AiUsageLimitIndicator(
                used: 7, // TODO: Replace with real usage value
                limit: 10, // TODO: Replace with real limit value
                isPremium: false, // TODO: Replace with real premium status
              ),
            ),
            Container(
              color: Colors.white,
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
    );
  }
}

class _AIChatTabContent extends StatelessWidget {
  const _AIChatTabContent();

  @override
  Widget build(BuildContext context) {
    return Column(
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
    return BlocBuilder<ChatListCubit, ChatListState>(
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
                    // Llama a la función del padre a través de un callback
                    onPressed: () =>
                        (context
                                .findAncestorWidgetOfExactType<
                                  ChatListScreen
                                >())!
                            .onGoToPsychologists(),
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
    );
  }

  Widget _buildPsychologistChatCard(
    BuildContext context, {
    required PsychologistChatItem chatItem,
  }) {
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
              psychologistImageUrl:
                  chatItem.psychologistImageUrl ??
                  'https://via.placeholder.com/150',
            ),
          ),
        );
      },
    );
  }
}
