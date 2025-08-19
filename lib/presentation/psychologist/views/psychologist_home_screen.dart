// lib/presentation/psychologist/views/psychologist_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/profile_screen_psychologist.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_content.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_chat_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_management_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointment_confirmation_screen.dart';
import 'package:ai_therapy_teteocan/presentation/theme/views/theme_settings_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';

class PsychologistHomeScreen extends StatefulWidget {
  const PsychologistHomeScreen({super.key});

  @override
  _PsychologistHomeScreenState createState() => _PsychologistHomeScreenState();
}

class _PsychologistHomeScreenState extends State<PsychologistHomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _getWidgetOptions(String psychologistId) {
    return <Widget>[
      const PsychologistHomeContent(),
      const PsychologistChatListScreen(),
      BlocProvider<AppointmentBloc>(
        create: (context) => AppointmentBloc(),
        child: AppointmentsListScreen(psychologistId: psychologistId),
      ),
      const PatientManagementScreen(),
      const ProfileScreenPsychologist(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

    return BlocProvider<ChatListBloc>(
      create: (context) => ChatListBloc(),
      child: Scaffold(
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
                'Hello, $userName',
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
            // BOTÓN TEMPORAL PARA VER PANTALLA DE CONFIRMACIÓN
            IconButton(
              icon: Icon(
                Icons.calendar_view_day,
                color: Theme.of(context).appBarTheme.iconTheme?.color,
              ),
              onPressed: () {
                // Crear una cita de ejemplo para mostrar la pantalla de confirmación
                final sampleAppointment = AppointmentModel(
                  id: 'sample_appointment_001',
                  patientId: 'patient_001',
                  patientName: 'María García',
                  patientEmail: 'maria.garcia@email.com',
                  psychologistId: psychologistId,
                  psychologistName: userName,
                  psychologistSpecialty: 'Psicología Clínica',
                  scheduledDateTime: DateTime.now().add(
                    const Duration(days: 1),
                  ),
                  type: AppointmentType.online,
                  status: AppointmentStatus.pending,
                  price: 500.0,
                  notes:
                      'Sesión inicial para evaluación de ansiedad y depresión',
                  createdAt: DateTime.now(),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider<AppointmentBloc>(
                      create: (context) => AppointmentBloc(),
                      child: AppointmentConfirmationScreen(
                        appointment: sampleAppointment,
                      ),
                    ),
                  ),
                );
              },
              tooltip: 'Ver Pantalla de Confirmación (Prueba)',
            ),
            IconButton(
              icon: Icon(
                Icons.notifications_none,
                color: Theme.of(context).appBarTheme.iconTheme?.color,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ver notificaciones')),
                );
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: widgetOptions[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(
            context,
          ).bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: Theme.of(
            context,
          ).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(
            context,
          ).bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle:
              Theme.of(context).bottomNavigationBarTheme.selectedLabelStyle ??
              const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
          unselectedLabelStyle:
              Theme.of(context).bottomNavigationBarTheme.unselectedLabelStyle ??
              const TextStyle(
                fontWeight: FontWeight.normal,
                fontFamily: 'Poppins',
              ),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Citas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Pacientes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
