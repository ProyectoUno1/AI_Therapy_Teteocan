// lib/presentation/psychologist/views/psychologist_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart'; 
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/profile_screen_psychologist.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_content.dart';


class PsychologistHomeScreen extends StatefulWidget {

  @override
  _PsychologistHomeScreenState createState() => _PsychologistHomeScreenState();
}

class _PsychologistHomeScreenState extends State<PsychologistHomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _getWidgetOptions(BuildContext context) {
    return <Widget>[
      const PsychologistHomeContent(),
      Center(
        child: Text(
          'Chats con Pacientes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      Center(
        child: Text(
          'Herramientas para Psicólogos',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      ProfileScreenPsychologist(),
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
    String? profilePictureUrl;

    final authState = context.watch<AuthBloc>().state;

  
    if (authState.isAuthenticatedPsychologist) { 
      userName = authState.psychologist!.username; 
      profilePictureUrl = authState.psychologist!.profilePictureUrl;
    }
   

    final List<Widget> widgetOptions = _getWidgetOptions(context);

    return Scaffold(
      backgroundColor: AppConstants.lightGreyBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.lightGreyBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuración')),
            );
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello, $userName',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '👋',
              style: TextStyle(fontSize: 18),
            ),
          ],
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
          const SizedBox(width: 10),
        ],
      ),
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppConstants.lightGreyBackground,
        selectedItemColor: AppConstants.secondaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontFamily: 'Poppins',
        ),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}