// lib/presentation/psychologist/views/psychologist_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/profile_screen_psychologist.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_content.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_chat_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_management_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/theme/views/theme_settings_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_management_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/notification_panel_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';

class PsychologistHomeScreen extends StatefulWidget {
  final int? initialTabIndex;

  const PsychologistHomeScreen({
    super.key,
    this.initialTabIndex,
  });

  @override
  _PsychologistHomeScreenState createState() => _PsychologistHomeScreenState();
}

class _PsychologistHomeScreenState extends State<PsychologistHomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _notificationsLoaded = false;

  void _navigateToChatTab() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  List<Widget> _getWidgetOptions(String psychologistId) {
  return <Widget>[
    const PsychologistHomeContent(),
    // RESTAURAR el BlocProvider local
    BlocProvider<ChatListBloc>(
      create: (context) => ChatListBloc(),
      child: const PsychologistChatListScreen(),
    ),
    BlocProvider<AppointmentBloc>(
      create: (context) => AppointmentBloc(),
      child: AppointmentsListScreen(psychologistId: psychologistId),
    ),
    BlocProvider<PatientManagementBloc>(
      create: (context) => PatientManagementBloc(),
      child: const PatientManagementScreen(),
    ),
    const ProfileScreenPsychologist(),
  ];
}
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _loadNotifications(BuildContext context) async {
    if (_notificationsLoaded) return;
    
    final user = _auth.currentUser;
    if (user != null && mounted) {
      final token = await user.getIdToken();
      if (token != null) {
        context.read<NotificationBloc>().add(
          LoadNotifications(
            userId: user.uid,
            userToken: token,
            userType: 'psychologist',
          ),
        );
        _notificationsLoaded = true;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _notificationsLoaded = false;
  
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = 'Psicólogo';
    final authState = context.watch<AuthBloc>().state;

    if (authState.isAuthenticatedPsychologist) {
      userName = authState.psychologist!.username;
    }

    final psychologistId = authState.psychologist?.username ?? '';
    final widgetOptions = _getWidgetOptions(psychologistId);

    // Cargar notificaciones cuando el widget se construye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications(context);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        leading: IconButton(
          icon: Icon(
            Icons.settings,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ThemeSettingsScreen(),
              ),
            );
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hola, $userName',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 8),
            const Text('👋', style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationLoaded) {
                unreadCount = state.notifications.where((n) => !n.isRead).length;
              }
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Theme.of(context).appBarTheme.iconTheme?.color,
                    ),
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user != null) {
                        final token = await user.getIdToken();
                        if (token != null) {
                          // Recargar notificaciones antes de abrir el panel
                          context.read<NotificationBloc>().add(
                            LoadNotifications(
                              userId: user.uid,
                              userToken: token,
                              userType: 'psychologist',
                            ),
                          );
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPanelScreen(),
                            ),
                          ).then((_) {
                            // Recargar notificaciones al regresar
                            context.read<NotificationBloc>().add(
                              LoadNotifications(
                                userId: user.uid,
                                userToken: token,
                                userType: 'psychologist',
                              ),
                            );
                          });
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario no autenticado')),
                        );
                      }
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B716F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        selectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.selectedLabelStyle ??
            const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        unselectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.unselectedLabelStyle ??
            const TextStyle(fontWeight: FontWeight.normal, fontFamily: 'Poppins'),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}