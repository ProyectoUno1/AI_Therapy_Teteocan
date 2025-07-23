import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/screens/patient/profile_screen_patient.dart';
// Importa Firebase Auth para obtener el nombre del usuario
// import 'package:firebase_auth/firebase_auth.dart';
// Importa la pantalla de perfil para la navegación (si aplica)

class PatientHomeScreen extends StatefulWidget {
  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  String _userName = 'Paciente'; // Nombre por defecto para pacientes
  int _selectedIndex = 0; // Índice del BottomNavigationBar seleccionado

  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Método para cargar el nombre del usuario autenticado
  void _loadUserName() {
    // Descomenta esta sección cuando tengas Firebase Auth configurado
    /*
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Paciente';
      });
    }
    */
  }

  // Lista de widgets para las diferentes pestañas del BottomNavigationBar
  // Aquí puedes añadir las pantallas reales para cada sección
  static List<Widget> _widgetOptions = <Widget>[
    Center(
      child: Text(
        'Contenido principal del Paciente\n(Aquí irá la IA de terapia y más)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    Center(
      child: Text(
        'Chats del Paciente',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    Center(
      child: Text(
        'Psicólogos disponibles para el Paciente',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    ProfileScreenPatient(), // La pantalla de perfil ya creada
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Puedes añadir lógica de navegación aquí si las pantallas no son parte del PageView
    // Por ejemplo, si ProfileScreen no está en _widgetOptions directamente
    if (index == 3) {
      // Si la pantalla de perfil es una ruta separada y no parte del PageView
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: accentColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Lógica para abrir el menú lateral (Drawer)
            Scaffold.of(context).openDrawer();
          },
        ),
        title: Text(
          'Hola, $_userName',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Lógica para ver notificaciones
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Ver notificaciones')));
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(
          _selectedIndex,
        ), // Muestra el widget de la pestaña seleccionada
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: lightAccentColor,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontFamily: 'Poppins',
        ),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Psicólogos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
