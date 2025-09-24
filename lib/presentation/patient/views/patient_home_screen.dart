// lib/presentation/patient/views/patient_home_screen.dart

import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/chat_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_content.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/profile_screen_patient.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/psychologists_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/notification_panel_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_event.dart';
import 'package:ai_therapy_teteocan/data/repositories/notification_repository.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';

class PatientHomeScreen extends StatefulWidget {
  final String? initialChatPsychologistId;
  final String? initialChatId;

  const PatientHomeScreen({
    super.key,
    this.initialChatPsychologistId,
    this.initialChatId,
  });

  @override
  State<PatientHomeScreen> createState() => PatientHomeScreenState();
}

class PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToPsychologistsScreen() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _goToChatScreen() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  List<Widget> _buildWidgetOptions(String patientId) {
    return <Widget>[
      PatientHomeContent(patientId: patientId),
      ChatListScreen(
        onGoToPsychologists: _goToPsychologistsScreen,
        initialPsychologistId: widget.initialChatPsychologistId,
        initialChatId: widget.initialChatId,
      ),
      const PsychologistsListScreen(),
      const PatientAppointmentsListScreen(),
      const ProfileScreenPatient(),
    ];
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.initialChatPsychologistId != null || widget.initialChatId != null) {
      _selectedIndex = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    String userName = 'Paciente';
    final authState = context.watch<AuthBloc>().state;
    if (authState.patient != null) {
      userName = authState.patient!.username;
    }

    final user = FirebaseAuth.instance.currentUser;

    // Si no hay paciente autenticado, mostrar un indicador de carga o error
    if (authState.patient == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Crear _widgetOptions cada vez en build con el patientId actual
    final widgetOptions = _buildWidgetOptions(authState.patient!.uid);

    return FutureBuilder<String?>(
      future: user?.getIdToken(),
      builder: (context, snapshot) {
        final String? userToken = snapshot.data;
        final bool isTokenLoading = snapshot.connectionState == ConnectionState.waiting;
        final bool isUserAuthenticated = user != null && userToken != null && authState.patient != null;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: false,
            title: Text(
              'Buen día, $userName 👋',
              style: TextStyle(
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              if (isTokenLoading)
                const Center(child: CircularProgressIndicator())
              else if (isUserAuthenticated)
                BlocProvider(
                  create: (context) => NotificationBloc(
                    notificationRepository: NotificationRepository(),
                  )..add(
                      LoadNotifications(
                        userId: authState.patient!.uid,
                        userToken: userToken,
                        userType: 'patient',
                      ),
                    ),
                  child: BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      int unreadCount = 0;
                      if (state is NotificationLoaded) {
                        unreadCount = state.notifications.where((n) => !n.isRead).length;
                      }
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _notificationsEnabled
                                  ? Icons.notifications_none
                                  : Icons.notifications_off,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            onPressed: () {
                              final notificationBloc = BlocProvider.of<NotificationBloc>(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider.value(
                                    value: notificationBloc,
                                    child: NotificationsPanelScreen(
                                      onNavigateToChat: _goToChatScreen,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF3B716F),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    _notificationsEnabled
                        ? Icons.notifications_none
                        : Icons.notifications_off,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario no autenticado')),
                    );
                  },
                ),
            ],
          ),
          body: widgetOptions[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
            unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontFamily: 'Poppins',
            ),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology),
                label: 'Psicólogos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Citas',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }
}