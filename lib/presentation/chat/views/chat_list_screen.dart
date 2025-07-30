// lib/presentation/chat/views/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/ai_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
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
          Expanded(
            child: TabBarView(
              children: [_buildAIChatList(), _buildPsychologistsChatList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIChatList() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildAIChatCard(),
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
                  Text(
                    'Aurora AI está aquí para ayudarte',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Habla sobre cualquier tema que te preocupe',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
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

  Widget _buildAIChatCard() {
    return Builder(
      builder: (context) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: AppConstants.lightAccentColor.withOpacity(0.2),
            child: Icon(Icons.psychology, color: AppConstants.lightAccentColor),
          ),
          title: const Text(
            'Aurora AI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: const Text(
            'Tu asistente terapéutico 24/7',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.lightAccentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Activo',
              style: TextStyle(
                color: AppConstants.lightAccentColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatScreen()),
            );
          },
        );
      },
    );
  }

  Widget _buildPsychologistsChatList() {
    // Por ahora, mostraremos un mensaje temporal
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay chats activos con psicólogos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Programa una sesión para comenzar a chatear',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navegar a la lista de psicólogos
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.lightAccentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
