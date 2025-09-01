import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/chat_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_content.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/profile_screen_patient.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/psychologists_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => PatientHomeScreenState();
}

class PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;

  late final List<Widget> _widgetOptions = <Widget>[
    const PatientHomeContent(),
    ChatListScreen(onGoToPsychologists: _goToPsychologistsScreen),
    const PsychologistsListScreen(),
    const PatientAppointmentsListScreen(),
    const ProfileScreenPatient(),
  ];

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

  @override
  Widget build(BuildContext context) {
    String userName = 'Paciente';
    final authState = context.watch<AuthBloc>().state;
    if (authState.patient != null) {
      userName = authState.patient!.username;
    }

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
          IconButton(
            icon: Icon(
              _notificationsEnabled
                  ? Icons.notifications_none
                  : Icons.notifications_off,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              setState(() {
                _notificationsEnabled = !_notificationsEnabled;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _notificationsEnabled
                        ? 'Notificaciones activadas'
                        : 'Notificaciones desactivadas',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => AppointmentBloc(),
        child: _widgetOptions[_selectedIndex],
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Psicólogos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}