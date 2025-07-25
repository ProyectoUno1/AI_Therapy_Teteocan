import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart'; // Importa AuthState con los nuevos estados
import 'package:ai_therapy_teteocan/presentation/psychologist/views/profile_screen_psychologist.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_content.dart';
// Importa tus modelos de dominio si son necesarios para castear la UserEntity
import 'package:ai_therapy_teteocan/domain/entities/user_entity.dart';
import 'package:ai_therapy_teteocan/domain/entities/psychologist_entity.dart'; // Si necesitas acceder a propiedades específicas del PsychologistEntity
import 'package:ai_therapy_teteocan/data/models/psychologist_models.dart'; // Si AuthBloc te devuelve el Model en lugar de la Entity


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

    // --- CAMBIO CLAVE AQUÍ ---
    if (authState.status == AuthStatus.authenticatedPsychologist && authState.user != null) {
      // Intentamos castear la UserEntity a PsychologistEntity
      if (authState.user is PsychologistEntity) {
        final psychologistEntity = authState.user as PsychologistEntity;
        userName = psychologistEntity.username;
        profilePictureUrl = psychologistEntity.profilePictureUrl;
      } else if (authState.user is PsychologistModel) { // En caso de que el bloc emita el modelo directamente
        final psychologistModel = authState.user as PsychologistModel;
        userName = psychologistModel.username;
        profilePictureUrl = psychologistModel.profilePictureUrl;
      }
      // Si authState.user es solo UserEntity, usará su username y profilePictureUrl si existen
      else {
         userName = authState.user!.username;
         profilePictureUrl = authState.user!.profilePictureUrl;
      }
    }
    // --- FIN CAMBIO CLAVE ---


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
          
          const SizedBox(width: 10),
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