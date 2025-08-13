import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_chat_screen.dart';
import 'package:ai_therapy_teteocan/data/models/patient_chat_item.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_state.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_bloc.dart'; // Importación correcta del BLoC unificado

class PsychologistChatListScreen extends StatefulWidget {
  const PsychologistChatListScreen({super.key});

  @override
  State<PsychologistChatListScreen> createState() =>
      _PsychologistChatListScreenState();
}

class _PsychologistChatListScreenState
    extends State<PsychologistChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      BlocProvider.of<ChatListBloc>(context).add(SearchChats(query));
    });

    final authState = BlocProvider.of<AuthBloc>(context).state;
    if (authState.isAuthenticatedPsychologist) {
      _currentUserId = authState.psychologist!.uid;
      BlocProvider.of<ChatListBloc>(context).add(LoadChats(_currentUserId!));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(child: _buildChatList(context)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar pacientes...',
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[100]
              : Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context) {
    return BlocBuilder<ChatListBloc, ChatListState>(
      builder: (context, state) {
        if (state is ChatListLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ChatListError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is ChatListLoaded) {
          final isSearching = _searchController.text.isNotEmpty;

          final chatsToShow = isSearching ? state.filteredChats : state.chats;

          if (chatsToShow.isEmpty) {
            return _buildEmptyState(isFiltered: isSearching);
          }

          return Container(
            color: Theme.of(context).cardColor,
            child: ListView.separated(
              itemCount: chatsToShow.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
              itemBuilder: (context, index) {
                final patient = chatsToShow[index];
                return _buildPatientChatTile(patient);
              },
            ),
          );
        }

        return _buildEmptyState(isFiltered: false);
      },
    );
  }

  Widget _buildEmptyState({required bool isFiltered}) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No se encontraron pacientes'
                  : 'No tienes chats activos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isFiltered
                    ? 'Intenta con otro término de búsqueda'
                    : 'Los pacientes aparecerán aquí cuando inicien conversaciones',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientChatTile(PatientChatItem patient) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppConstants.lightAccentColor.withOpacity(0.3),
            backgroundImage: NetworkImage(patient.profileImageUrl),
          ),
          if (patient.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              patient.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(patient.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: patient.isTyping
                ? Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Escribiendo...',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  )
                : Text(
                    patient.lastMessage,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
          ),
          if (patient.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                patient.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: context.read<ChatBloc>(),
              child: PatientChatScreen(
                patientId: patient.id,
                patientName: patient.name,
                patientImageUrl: patient.profileImageUrl,
                isPatientOnline: patient.isOnline,
              ),
            ),
          ),
        );
      },
    );
  }
}