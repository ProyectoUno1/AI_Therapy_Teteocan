import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as auth_provider;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variable para almacenar el nombre del usuario
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // Método para cargar el nombre del usuario autenticado
  void _loadUserName() {
    // Obtener el usuario del AuthProvider
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    setState(() {
      _userName = authProvider.userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF5CA0AC), // Color base de tu paleta
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Lógica para abrir el menú lateral (Drawer)
            Scaffold.of(context).openDrawer();
          },
        ),
        title: Text(
          'Hola, $_userName', // Saludo personalizado con el nombre del usuario
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight
                .w600, // Esto hará que se use Poppins-Bold si está configurado
            fontFamily: 'Poppins', // Opcional, ya que está en el tema global
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
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Cerrar sesión
              final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
              await authProvider.signOut();
              // La navegación se maneja automáticamente por el AuthWrapper
            },
          ),
          SizedBox(width: 10), // Espacio adicional
        ],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            // Aquí puedes añadir widgets para el contenido principal de la Home Page
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.0),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Un color neutro para el contenido
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Contenido principal de la Home Page\n(Aquí irá la IA de terapia)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // Asegura que todos los iconos se muestren
        backgroundColor: Color(0xFF3B716F), // Color base de tu paleta
        selectedItemColor: Color(0xFF82C4C3), // Color para el ítem seleccionado
        unselectedItemColor:
            Colors.white70, // Color para los ítems no seleccionados
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
            icon: Icon(Icons.psychology), // Ícono de psicología
            label: 'Psicólogos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: 0, // Índice del ítem seleccionado (Inicio por defecto)
        onTap: (index) {
          // Lógica para manejar la navegación entre las pestañas
          // Por ahora, solo muestra un SnackBar
          String message = '';
          switch (index) {
            case 0:
              message = 'Navegando a Inicio';
              break;
            case 1:
              message = 'Navegando a Chats';
              break;
            case 2:
              message = 'Navegando a Psicólogos';
              break;
            case 3:
              message = 'Navegando a Perfil';
              break;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      ),
    );
  }
}
