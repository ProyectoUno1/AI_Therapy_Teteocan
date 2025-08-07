// lib/presentation/psychologist/views/psychologist_chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_chat_screen.dart';

class PsychologistChatListScreen extends StatefulWidget {
  const PsychologistChatListScreen({super.key});

  @override
  State<PsychologistChatListScreen> createState() =>
      _PsychologistChatListScreenState();
}

class _PsychologistChatListScreenState
    extends State<PsychologistChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientChatItem> _filteredPatients = [];
  List<PatientChatItem> _allPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPatients() {
    // TODO: Cargar pacientes reales desde el backend
    _allPatients = [
      PatientChatItem(
        id: '1',
        name: 'María González',
        lastMessage: 'Hola doctor, ¿cómo está?',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        profileImageUrl: 'https://via.placeholder.com/60',
        isOnline: true,
        unreadCount: 2,
        isTyping: false,
      ),
      PatientChatItem(
        id: '2',
        name: 'Carlos Rodríguez',
        lastMessage: 'Gracias por la sesión de hoy',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        profileImageUrl: 'https://via.placeholder.com/60',
        isOnline: false,
        unreadCount: 0,
        isTyping: false,
      ),
      PatientChatItem(
        id: '3',
        name: 'Ana Martínez',
        lastMessage: 'Me siento mucho mejor después de nuestras conversaciones',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 4)),
        profileImageUrl: 'https://via.placeholder.com/60',
        isOnline: true,
        unreadCount: 1,
        isTyping: true,
      ),
      PatientChatItem(
        id: '4',
        name: 'Luis Fernández',
        lastMessage: 'Nos vemos la próxima semana',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        profileImageUrl: 'https://via.placeholder.com/60',
        isOnline: false,
        unreadCount: 0,
        isTyping: false,
      ),
    ];
    _filteredPatients = List.from(_allPatients);
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
            patient.lastMessage.toLowerCase().contains(query);
      }).toList();
    });
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
    return _buildPatientsChat();
  }

  Widget _buildPatientsChat() {
    return Column(
      children: [
        // Barra de búsqueda
        Container(
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
        ),

        // Lista de pacientes
        Expanded(
          child: _filteredPatients.isEmpty
              ? _buildEmptyState()
              : Container(
                  color: Theme.of(context).cardColor,
                  child: ListView.separated(
                    itemCount: _filteredPatients.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                    itemBuilder: (context, index) {
                      final patient = _filteredPatients[index];
                      return _buildPatientChatTile(patient);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
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
                _searchController.text.isNotEmpty
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientChatScreen(
              patientId: patient.id,
              patientName: patient.name,
              patientImageUrl: patient.profileImageUrl,
              isPatientOnline: patient.isOnline,
            ),
          ),
        );
      },
    );
  }
}

// Modelo para representar un chat con un paciente
class PatientChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String profileImageUrl;
  final bool isOnline;
  final int unreadCount;
  final bool isTyping;

  PatientChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.profileImageUrl,
    required this.isOnline,
    required this.unreadCount,
    required this.isTyping,
  });
}
