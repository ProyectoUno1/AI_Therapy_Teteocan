// lib/presentation/psychologist/views/psychologist_chat_list_screen.dart
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
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_chat_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/presentation/shared/approval_status_blocker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PsychologistChatListScreen extends StatefulWidget {
  const PsychologistChatListScreen({super.key});

  @override
  State<PsychologistChatListScreen> createState() =>
      _PsychologistChatListScreenState();
}

class _PsychologistChatListScreenState
    extends State<PsychologistChatListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;
  late AnimationController _animationController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _isSearching = query.isNotEmpty;
      });
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
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE', 'es').format(time);
      } else {
        return DateFormat('dd/MM/yy').format(time);
      }
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return ApprovalStatusBlocker(
          psychologist: authState.psychologist,
          featureName: 'chats',
          child: _buildChatContent(context, authState),
        );
      },
    );
  }

  // MODIFICADO: Cambiado a CustomScrollView para permitir el scroll
  // MODIFICADO: Envuelve el CustomScrollView en RefreshIndicator
Widget _buildChatContent(BuildContext context, AuthState authState) {
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: RefreshIndicator( // <-- ¡AQUÍ SE COLOCA!
      onRefresh: () async {
        if (_currentUserId != null) {
          // Reutilizamos la lógica de carga para el refresh
          BlocProvider.of<ChatListBloc>(context).add(LoadChats(_currentUserId!));
        }
      },
      color: AppConstants.secondaryColor,
      child: CustomScrollView( 
        slivers: [
          // 1. Encabezado principal
          SliverToBoxAdapter(
            child: _buildHeader(context, authState),
          ),
          
          // 2. Barra de búsqueda
          SliverToBoxAdapter(
            child: _buildSearchBar(context),
          ),
          
          // 3. La lista de chats o estados (como un Sliver)
          _buildChatListSliver(context), 
        ],
      ),
    ),
  );
}

  // MODIFICADO: Eliminado SafeArea para evitar doble padding con el Scaffold
  Widget _buildHeader(BuildContext context, AuthState authState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // SafeArea ELIMINADO
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Esto soluciona el overflow horizontal de 22px
          SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Añadido Expanded para evitar overflow horizontal
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Conversaciones',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<ChatListBloc, ChatListState>(
                        builder: (context, state) {
                          if (state is ChatListLoaded) {
                            final totalChats = state.chats.length;
                            final unreadCount = state.chats
                                .where((chat) => chat.unreadCount > 0)
                                .length;
                            
                            return Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$totalChats ${totalChats == 1 ? 'paciente' : 'pacientes'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$unreadCount nuevo${unreadCount != 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.filter_list_rounded,
                      color: AppConstants.secondaryColor,
                    ),
                    onPressed: () {
                      _showFilterOptions(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar pacientes...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppConstants.secondaryColor,
              size: 22,
            ),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

 // lib/presentation/psychologist/views/psychologist_chat_list_screen.dart
// ... (código anterior)

// MODIFICADO: Se añade hasScrollBody: false a SliverFillRemaining
Widget _buildChatListSliver(BuildContext context) {
  return BlocBuilder<ChatListBloc, ChatListState>(
    builder: (context, state) {
      if (state is ChatListLoading) {
        return SliverFillRemaining( 
          hasScrollBody: false, // <-- CORRECCIÓN
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: AppConstants.secondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando conversaciones...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (state is ChatListError) {
        return SliverFillRemaining(
          hasScrollBody: false, // CORRECCIÓN: Aplicado también para consistencia
          child: _buildErrorState(context, state.message),
        );
      }

      if (state is ChatListLoaded) {
        final isSearching = _searchController.text.isNotEmpty;
        final chatsToShow = isSearching ? state.filteredChats : state.chats;

        if (chatsToShow.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false, // CORRECCIÓN: Aplicado también para consistencia
            child: _buildEmptyState(isFiltered: isSearching),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList( 
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final patient = chatsToShow[index];
                return _buildPatientChatTile(patient, index);
              },
              childCount: chatsToShow.length,
            ),
          ),
        );
      }

      return const SliverToBoxAdapter(child: SizedBox.shrink());
    },
  );
}


  
  // Extraído el estado de error para ser llamado por SliverFillRemaining
  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: SingleChildScrollView( // Permite scroll en caso de pantalla pequeña
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar chats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentUserId != null) {
                  BlocProvider.of<ChatListBloc>(context)
                      .add(LoadChats(_currentUserId!));
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modificado: Envuelto en SingleChildScrollView para manejar overflow en modo 'SliverFillRemaining'
  Widget _buildEmptyState({required bool isFiltered}) {
    return Center(
      child: SingleChildScrollView( // Permite scroll en caso de overflow
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Esto es importante dentro del SingleChildScrollView
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFiltered
                      ? Icons.search_off_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: AppConstants.secondaryColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFiltered
                    ? 'No se encontraron pacientes'
                    : 'No tienes conversaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  isFiltered
                      ? 'Intenta buscar con otro nombre o término'
                      : 'Cuando los pacientes inicien conversaciones, aparecerán aquí',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (!isFiltered) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.lightAccentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.lightAccentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppConstants.lightAccentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Los pacientes pueden contactarte desde su perfil',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.lightAccentColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPatientChatTile(PatientChatItem patient, int index) {
  return TweenAnimationBuilder<double>(
    duration: Duration(milliseconds: 300 + (index * 50)),
    tween: Tween(begin: 0.0, end: 1.0),
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: child,
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider<PsychologistChatBloc>(
                  create: (context) => PsychologistChatBloc(),
                  child: PatientChatScreen(
                    patientId: patient.id,
                    patientName: patient.name,
                    patientImageUrl: patient.profileImageUrl,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAvatar(patient),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(patient.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: patient.unreadCount > 0
                                  ? AppConstants.secondaryColor
                                  : Colors.grey[500],
                              fontWeight: patient.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Solución de StreamBuilder
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(_getChatId(patient.id))
                            .snapshots(),
                        builder: (context, snapshot) {
                          String displayMessage = patient.lastMessage;
                          
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null && data['lastMessage'] != null) {
                              displayMessage = data['lastMessage'] as String;
                            }
                          }
                          
                          return Row(
                            children: [
                              Expanded(
                                child: patient.isTyping
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppConstants.secondaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Escribiendo...',
                                            style: TextStyle(
                                              color: AppConstants.secondaryColor,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        displayMessage, // Usar el mensaje de Firestore
                                        style: TextStyle(
                                          color: patient.unreadCount > 0
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color
                                              : Colors.grey[600],
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          fontWeight: patient.unreadCount > 0
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                              ),
                              if (patient.unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppConstants.primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    patient.unreadCount > 99
                                        ? '99+'
                                        : patient.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Método helper para construir el chatId
String _getChatId(String patientId) {
  if (_currentUserId == null) return '';
  final ids = [_currentUserId!, patientId]..sort();
  return '${ids[0]}_${ids[1]}';
}
  Widget _buildAvatar(PatientChatItem patient) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(patient.id)
          .snapshots(),
      builder: (context, snapshot) {
        bool isOnline = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          isOnline = data['isOnline'] ?? false;
        }

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: patient.unreadCount > 0
                      ? AppConstants.primaryColor
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: patient.unreadCount > 0
                        ? AppConstants.primaryColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppConstants.lightAccentColor.withOpacity(0.2),
                backgroundImage: patient.profileImageUrl.isNotEmpty
                    ? NetworkImage(patient.profileImageUrl)
                    : null,
                child: patient.profileImageUrl.isEmpty
                    ? Text(
                        patient.name.isNotEmpty
                            ? patient.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.secondaryColor,
                          fontFamily: 'Poppins',
                        ),
                      )
                    : null,
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // MODIFICADO: Añadido isScrollControlled y SingleChildScrollView para corregir el overflow vertical
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // ¡Permite al modal ocupar casi toda la altura y manejar el teclado!
      builder: (BuildContext bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView( // ¡Permite el scroll del contenido!
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Filtrar conversaciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterOption(
                    context,
                    icon: Icons.mark_chat_unread_rounded,
                    title: 'Mensajes no leídos',
                    subtitle: 'Mostrar solo chats con mensajes nuevos',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      // TODO: Implementar filtro
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFilterOption(
                    context,
                    icon: Icons.schedule_rounded,
                    title: 'Más recientes',
                    subtitle: 'Ordenar por última actividad',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      // TODO: Implementar filtro
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFilterOption(
                    context,
                    icon: Icons.sort_by_alpha_rounded,
                    title: 'Orden alfabético',
                    subtitle: 'Ordenar por nombre de paciente',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      // TODO: Implementar filtro
                    },
                  ),
                  // Se usa MediaQuery.of(context).viewInsets.bottom para dar espacio
                  // al teclado sin causar overflow, gracias a SingleChildScrollView y isScrollControlled.
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24), 
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppConstants.secondaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}