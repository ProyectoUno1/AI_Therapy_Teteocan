// lib/presentation/patient/views/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart'; // Importa AuthState
import 'package:ai_therapy_teteocan/presentation/patient/views/profile_screen_patient.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_content.dart';

class PatientHomeScreen extends StatefulWidget {
  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _getWidgetOptions(BuildContext context) {
    return <Widget>[
      const PatientHomeContent(),
      const Center(
        child: Text(
          'Chats del Paciente',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
        ),
      ),
      const Center(
        child: Text(
          'Psicólogos disponibles para el Paciente',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
        ),
      ),
       const ProfileScreenPatient()
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String userName = 'Paciente'; // Valor por defecto
    final authState = context.watch<AuthBloc>().state;

    if (authState.isAuthenticatedPatient) {
      userName = authState.patient!.username; // Accede directamente a 'patient'
    }

    final List<Widget> widgetOptions = _getWidgetOptions(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Buen dia, $userName 👋',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver notificaciones')),
              );
            },
          ),
        ],
      ),
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppConstants.lightAccentColor,
        unselectedItemColor: Colors.grey,
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}