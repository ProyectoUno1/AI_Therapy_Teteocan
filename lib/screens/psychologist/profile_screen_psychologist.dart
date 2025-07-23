import 'package:flutter/material.dart';
// Asegúrate de importar firebase_auth para la función de cerrar sesión y obtener el nombre de usuario
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/screens/auth/login_screen.dart'; // Para redirigir al cerrar sesión

class ProfileScreenPsychologist extends StatefulWidget {
  @override
  _ProfileScreenPsychologistState createState() =>
      _ProfileScreenPsychologistState();
}

class _ProfileScreenPsychologistState extends State<ProfileScreenPsychologist> {
  String _userName = 'Psicólogo'; // Nombre por defecto para psicólogos

  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    // Descomenta esta sección cuando tengas Firebase Auth configurado
    /*
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Psicólogo';
      });
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Configuración del Perfil
          _buildExpansionCard(
            title: 'CONFIGURACIÓN DEL PERFIL',
            children: [
              _buildProfileOption(context, 'Información personal', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonalInfoScreenPsychologist(),
                  ),
                );
              }),
              _buildProfileOption(context, 'Notificaciones', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreenPsychologist(),
                  ),
                );
              }),
              _buildProfileOption(context, 'Apariencia', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppearanceScreenPsychologist(),
                  ),
                );
              }),
              _buildProfileOption(context, 'Idioma', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LanguageScreenPsychologist(),
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: 20),

          // Sección de Perfil Profesional (Solo para psicólogos)
          _buildExpansionCard(
            title: 'PERFIL PROFESIONAL',
            children: [
              _buildProfileOption(context, 'Información profesional', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfessionalInfoScreenPsychologist(),
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: 20),

          // Sección de Cuenta Asociada (Solo para psicólogos)
          _buildExpansionCard(
            title: 'CUENTA ASOCIADA',
            children: [
              _buildProfileOption(
                context,
                'Información para recibir pagos',
                () {
                  /* Lógica de pagos */
                },
              ),
            ],
          ),
          SizedBox(height: 20),

          // Sección de Soporte
          _buildExpansionCard(
            title: 'SOPORTE',
            children: [
              _buildProfileOption(context, 'Soporte', () {
                /* Lógica de Soporte */
              }),
            ],
          ),
          SizedBox(height: 20),

          // Sección de Contratos
          _buildExpansionCard(
            title: 'CONTRATOS',
            children: [
              _buildProfileOption(context, 'Política de privacidad', () {
                /* Lógica de Política de Privacidad */
              }),
              // Puedes añadir más opciones de contratos aquí
            ],
          ),
          SizedBox(height: 30),

          // Botón de Cerrar Sesión
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                _showLogoutConfirmationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: Text(
                'CERRAR SESIÓN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  // Widget auxiliar para las tarjetas expandibles (secciones)
  Widget _buildExpansionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      // Asegura que el color de la tarjeta se adapte al tema
      color: Theme.of(context).cardColor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey(title),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    primaryColor, // El color del título de la sección puede ser oscuro o claro según tu diseño
                letterSpacing: 1.2,
                fontFamily: 'Poppins',
              ),
            ),
            iconColor: primaryColor,
            collapsedIconColor: primaryColor,
            children: <Widget>[
              Divider(height: 1, color: lightAccentColor.withOpacity(0.5)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(children: children),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para cada opción dentro de una sección
  Widget _buildProfileOption(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                // Usa el color del texto del tema para que se adapte
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // Diálogo de confirmación para cerrar sesión
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar tu sesión?',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancelar',
                style: TextStyle(color: accentColor, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Sí, Cerrar Sesión',
                style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() async {
    // Lógica para cerrar sesión (Firebase Auth)
    /*
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sesión cerrada exitosamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
    */
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Simulando cierre de sesión...')));
    print('Cerrar Sesión');
    // Redirigir al Login después de la simulación
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}

// --- Sub-pantallas específicas para el perfil del psicólogo ---

class PersonalInfoScreenPsychologist extends StatelessWidget {
  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Información Personal',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: lightAccentColor,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Foto de perfil',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Text(
              'INFORMACIÓN PERSONAL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.8,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10),
            _buildInfoField(
              'Nombre',
              'Psicólogo',
              isEditable: true,
              context: context,
            ),
            _buildInfoField(
              'Fecha de nacimiento',
              '00/00/0000',
              isEditable: true,
              context: context,
            ),
            _buildInfoField(
              'Género',
              'Femenino/Masculino',
              isEditable: true,
              context: context,
            ),
            _buildInfoField(
              'Número de teléfono',
              '1234567890',
              isEditable: true,
              context: context,
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Guardando cambios...')),
                  );
                  // Lógica para guardar la información
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              label: Text(
                'Regresar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _showHelpDialog(
                  context,
                  'información personal',
                  'En la sección de información personal puedes cambiar tus datos personales.',
                );
              },
              icon: Icon(Icons.help_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value, {
    bool isEditable = false,
    int maxLines = 1,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          TextField(
            controller: TextEditingController(text: value),
            readOnly: !isEditable,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String section, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Duda Sección $section',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: TextStyle(fontFamily: 'Poppins')),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Entendido',
                style: TextStyle(color: accentColor, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ProfessionalInfoScreenPsychologist extends StatelessWidget {
  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Información Profesional',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: lightAccentColor,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Foto de perfil',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Text(
              'INFORMACIÓN PROFESIONAL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.8,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10),
            _buildInfoField(
              'Especialidad',
              'Depresión',
              isEditable: true,
              context: context,
            ),
            _buildInfoField(
              'Horario',
              'Horario en el que esta disponible',
              isEditable: true,
              context: context,
            ),
            _buildInfoField(
              'Sobre mí',
              'Descripción o información del psicólogo',
              isEditable: true,
              maxLines: 5,
              context: context,
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Guardando cambios...')),
                  );
                  // Lógica para guardar la información
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              label: Text(
                'Regresar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _showHelpDialog(
                  context,
                  'información profesional',
                  'Aquí puedes editar tu especialidad, horario y una descripción sobre ti.',
                );
              },
              icon: Icon(Icons.help_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value, {
    bool isEditable = false,
    int maxLines = 1,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          TextField(
            controller: TextEditingController(text: value),
            readOnly: !isEditable,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String section, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Duda Sección $section',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: TextStyle(fontFamily: 'Poppins')),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Entendido',
                style: TextStyle(color: accentColor, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class NotificationsScreenPsychologist extends StatefulWidget {
  @override
  _NotificationsScreenPsychologistState createState() =>
      _NotificationsScreenPsychologistState();
}

class _NotificationsScreenPsychologistState
    extends State<NotificationsScreenPsychologist> {
  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  bool _receiveNotifications = true; // Un solo toggle para recibir/no recibir

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'NOTIFICACIONES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.8,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10),
            // Opción única para controlar las notificaciones
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recibir notificaciones',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Switch(
                    value: _receiveNotifications,
                    onChanged: (bool value) {
                      setState(() {
                        _receiveNotifications = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Notificaciones activadas'
                                : 'Notificaciones desactivadas',
                          ),
                        ),
                      );
                    },
                    activeColor: lightAccentColor,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Configura tus preferencias de notificación para mantenerte al tanto de las novedades y mensajes importantes de Aurora.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              label: Text(
                'Regresar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _showHelpDialog(
                  context,
                  'notificaciones',
                  'En la sección de notificaciones puedes activar o desactivar las notificaciones cuando lo desees.',
                );
              },
              icon: Icon(Icons.help_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String section, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Duda Sección $section',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: TextStyle(fontFamily: 'Poppins')),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Entendido',
                style: TextStyle(color: accentColor, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class AppearanceScreenPsychologist extends StatefulWidget {
  @override
  _AppearanceScreenPsychologistState createState() =>
      _AppearanceScreenPsychologistState();
}

class _AppearanceScreenPsychologistState
    extends State<AppearanceScreenPsychologist> {
  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  String _selectedTheme = 'system'; // 'system', 'light', 'dark'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Apariencia',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'APARIENCIA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.8,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10),
            _buildThemeOption('Tema del sistema', 'system', context),
            _buildThemeOption('Tema claro', 'light', context),
            _buildThemeOption('Tema oscuro', 'dark', context),
            SizedBox(height: 20),
            Text(
              'Elige cómo quieres que se vea la aplicación. El tema del sistema se ajustará automáticamente según la configuración de tu dispositivo.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              label: Text(
                'Regresar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _showHelpDialog(
                  context,
                  'apariencia',
                  'En la sección de apariencia puedes activar el tema que más te agrade a la vista.',
                );
              },
              icon: Icon(Icons.help_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    String themeValue,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTheme = themeValue;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tema cambiado a: $title')));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Radio<String>(
              value: themeValue,
              groupValue: _selectedTheme,
              onChanged: (String? value) {
                setState(() {
                  _selectedTheme = value!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tema cambiado a: $title')),
                );
              },
              activeColor: primaryColor,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String section, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Duda Sección $section',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: TextStyle(fontFamily: 'Poppins')),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Entendido',
                style: TextStyle(color: accentColor, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class LanguageScreenPsychologist extends StatefulWidget {
  @override
  _LanguageScreenPsychologistState createState() =>
      _LanguageScreenPsychologistState();
}

class _LanguageScreenPsychologistState
    extends State<LanguageScreenPsychologist> {
  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  String _selectedLanguage = 'es'; // 'es' for Español, 'en' for Inglés

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Idioma',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'IDIOMA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.8,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10),
            _buildLanguageOption('Español', 'es', context),
            _buildLanguageOption('Inglés', 'en', context),
            SizedBox(height: 20),
            Text(
              'Selecciona el idioma de la aplicación para una mejor experiencia de usuario.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              label: Text(
                'Regresar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _showHelpDialog(
                  context,
                  'idioma',
                  'En la sección de idioma puedes activar el idioma que mejor comprendas.',
                );
              },
              icon: Icon(Icons.help_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    String title,
    String langCode,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = langCode;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Idioma cambiado a: $title')));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Radio<String>(
              value: langCode,
              groupValue: _selectedLanguage,
              onChanged: (String? value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Idioma cambiado a: $title')),
                );
              },
              activeColor: primaryColor,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String section, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Duda Sección $section',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: TextStyle(fontFamily: 'Poppins')),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Entendido',
                style: TextStyle(color: accentColor, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
