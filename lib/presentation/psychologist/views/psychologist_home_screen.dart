import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/profile_screen_psychologist.dart';

class PsychologistHomeScreen extends StatefulWidget {
  @override
  _PsychologistHomeScreenState createState() => _PsychologistHomeScreenState();
}

class _PsychologistHomeScreenState extends State<PsychologistHomeScreen> {
  int _selectedIndex = 0; // Índice del BottomNavigationBar seleccionado

  // Lista de widgets para las diferentes pestañas del BottomNavigationBar
  // Ahora se inicializa en el método build para asegurar que el contexto esté disponible.
  List<Widget> _getWidgetOptions(BuildContext context) {
    return <Widget>[
      Center(
        child: Text(
          'Panel de Control del Psicólogo\n(Aquí verás tus pacientes, citas, etc.)',
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
      ProfileScreenPsychologist(), // La pantalla de perfil para psicólogos
    ];
  }

  @override
  void initState() {
    super.initState();
    // _widgetOptions ya no se inicializa aquí
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el estado del AuthBloc para obtener el nombre del usuario
    String userName = 'Psicólogo';
    final authState = context
        .watch<AuthBloc>()
        .state; // Acceso directo al estado del BLoC
    if (authState.user != null) {
      userName = authState.user!.username;
    }

    // Inicializa _widgetOptions aquí, donde el contexto ya está disponible
    final List<Widget> widgetOptions = _getWidgetOptions(context);

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Adapta el color de fondo al tema
      appBar: AppBar(
        backgroundColor: AppConstants.accentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(
              context,
            ).openDrawer(); // Lógica para abrir el menú lateral
          },
        ),
        title: Text(
          'Hola, $userName',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver notificaciones')),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: widgetOptions.elementAt(
          _selectedIndex,
        ), // Muestra el widget de la pestaña seleccionada
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppConstants.primaryColor,
        selectedItemColor: AppConstants.lightAccentColor,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontFamily: 'Poppins',
        ),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman),
            label: 'Herramientas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
