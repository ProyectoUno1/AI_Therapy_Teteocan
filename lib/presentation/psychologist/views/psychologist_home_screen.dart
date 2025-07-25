import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/profile_screen_psychologist.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_content.dart';
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart'; // Ensure this is correctly imported if needed

class PsychologistHomeScreen extends StatefulWidget {
  const PsychologistHomeScreen({super.key}); // Added Key for best practices

  @override
  _PsychologistHomeScreenState createState() => _PsychologistHomeScreenState();
}

class _PsychologistHomeScreenState extends State<PsychologistHomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _getWidgetOptions(BuildContext context) {
    return <Widget>[
      const PsychologistHomeContent(), // This is now correctly a StatelessWidget
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
      ProfileScreenPsychologist(), // Assuming ProfileScreenPsychologist is also a StatelessWidget or StatefulWidget with a const constructor
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

    if (authState.status == AuthStatus.authenticatedPsychologist && authState.user != null) {
      if (authState.user is PsychologistEntity) {
        final psychologistEntity = authState.user as PsychologistEntity;
        userName = psychologistEntity.username;
        profilePictureUrl = psychologistEntity.profilePictureUrl;
      } else if (authState.user is PsychologistModel) {
        // If the AuthBloc happens to emit a PsychologistModel directly
        final psychologistModel = authState.user as PsychologistModel;
        userName = psychologistModel.username;
        profilePictureUrl = psychologistModel.profilePictureUrl;
      } else if (authState.user is UserEntity) {
        // Fallback for a generic UserEntity if it has these properties
        userName = authState.user!.username;
        profilePictureUrl = authState.user!.profilePictureUrl;
      }
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