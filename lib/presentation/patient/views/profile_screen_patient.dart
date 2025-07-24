import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart'; // Para redirigir al cerrar sesión
import 'package:ai_therapy_teteocan/presentation/shared/profile_list_item.dart'; // NUEVO WIDGET REUTILIZABLE

// Importaciones para las sub-pantallas
import 'package:image_picker/image_picker.dart'; // Importa image_picker
import 'dart:io'; // Para File

class ProfileScreenPatient extends StatefulWidget {
  @override
  _ProfileScreenPatientState createState() => _ProfileScreenPatientState();
}

class _ProfileScreenPatientState extends State<ProfileScreenPatient> {
  // Colores de tu paleta
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  @override
  Widget build(BuildContext context) {
    // El AppBar se maneja en PatientHomeScreen, este widget es solo el cuerpo
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0), // Padding general
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Espacio superior
          // Sección de información de perfil (Foto, Nombre, Email)
          // Adaptado del diseño de FlutterFlow
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String userName = 'Usuario';
              String userEmail = 'email@ejemplo.com';
              // Aquí podrías obtener la URL de la foto de perfil si la tienes en tu UserEntity
              // String? profileImageUrl = (authState.user as PatientEntity?)?.profilePictureUrl;

              if (authState.user != null) {
                userName = authState.user!.username;
                userEmail = authState.user!.email;
              }
              return Row(
                children: [
                  CircleAvatar(
                    radius: 28, // Tamaño similar al diseño de FlutterFlow
                    backgroundColor:
                        lightAccentColor, // Color de fondo para la foto
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    ),
                    // Si tienes una URL de imagen de perfil, úsala aquí:
                    // backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24), // Espacio después de la sección de perfil
          // Sección "Account" (Configuración del Perfil)
          Text(
            'Account', // Título de la sección como en el diseño de FlutterFlow
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color, // Color más tenue
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).cardColor, // Color de la tarjeta adaptable al tema
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).dividerColor.withOpacity(0.5), // Borde sutil
              ),
            ),
            child: Column(
              children: [
                ProfileListItem(
                  icon: Icons.info_outline, // Icono adaptado
                  text: 'Información personal',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalInfoScreenPatient(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.notifications_none, // Icono adaptado
                  text: 'Notificaciones',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreenPatient(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.palette_outlined, // Icono adaptado
                  text: 'Apariencia',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppearanceScreenPatient(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.language_outlined, // Icono adaptado
                  text: 'Idioma',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LanguageScreenPatient(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección "General" (Soporte, Contratos, etc.)
          Text(
            'General', // Título de la sección como en el diseño de FlutterFlow
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                ProfileListItem(
                  icon: Icons.help_outline,
                  text: 'Soporte',
                  onTap: () {
                    /* Lógica de Soporte */
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.privacy_tip_outlined,
                  text: 'Política de privacidad',
                  onTap: () {
                    /* Lógica de Política de Privacidad */
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.share_outlined,
                  text: 'Invitar Amigos',
                  onTap: () {
                    /* Lógica de Invitar Amigos */
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Botón de Cerrar Sesión
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.unauthenticated &&
                  !Navigator.of(context).canPop()) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión cerrada exitosamente.')),
                );
              } else if (state.status == AuthStatus.error &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.status == AuthStatus.loading
                      ? null
                      : () {
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
                  child: state.status == AuthStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'CERRAR SESIÓN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 50),
        ],
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
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
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
              child: const Text(
                'Sí, Cerrar Sesión',
                style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        );
      },
    );
  }
}

// --- Sub-pantallas específicas para el perfil del paciente (actualizadas) ---

class PersonalInfoScreenPatient extends StatefulWidget {
  @override
  _PersonalInfoScreenPatientState createState() =>
      _PersonalInfoScreenPatientState();
}

class _PersonalInfoScreenPatientState extends State<PersonalInfoScreenPatient> {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController(
    text: 'Usuario 123',
  );
  final TextEditingController _dobController = TextEditingController(
    text: '00/00/0000',
  );
  final TextEditingController _genderController = TextEditingController(
    text: 'Femenino/Masculino',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '1234567890',
  );

  // Variable para la URL de la imagen de perfil
  File? _profileImageFile; // Usamos File de dart:io para la imagen seleccionada

  @override
  void initState() {
    super.initState();
    // Aquí podrías cargar la información real del usuario desde un BLoC/Cubit
    // Por ejemplo: context.read<UserProfileCubit>().loadProfile();
    // Y actualizar los controladores con los datos.
  }

  // Método para seleccionar y simular subida de una foto
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImageFile = File(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto seleccionada. Ahora puedes guardarla.'),
          ),
        );
        // Aquí llamarías a un evento de BLoC para subir la imagen al almacenamiento (Firebase Storage)
        // y actualizar la URL en la base de datos del usuario.
        // Ejemplo: context.read<UserProfileBloc>().add(UploadProfilePicture(imageFile: _profileImageFile!));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ninguna foto.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información Personal',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                  GestureDetector(
                    onTap:
                        _pickImage, // Ahora llama a la lógica real de image_picker
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: lightAccentColor,
                          backgroundImage: _profileImageFile != null
                              ? FileImage(_profileImageFile!)
                              : null,
                          child: _profileImageFile == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryColor,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Toca para cambiar foto', // Texto más claro para la acción
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
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
            const SizedBox(height: 10),
            _buildInputFieldWithLabel(_nameController, 'Nombre', context),
            _buildInputFieldWithLabel(
              _dobController,
              'Fecha de nacimiento',
              context,
            ),
            _buildInputFieldWithLabel(_genderController, 'Género', context),
            _buildInputFieldWithLabel(
              _phoneController,
              'Número de teléfono',
              context,
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Guardando cambios...')),
                  );
                  // Lógica para guardar la información (disparar evento a un BLoC de perfil)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
        ),
      ),
      // Eliminado BottomAppBar redundante
    );
  }

  // Nuevo widget de campo de texto con label y diseño mejorado
  Widget _buildInputFieldWithLabel(
    TextEditingController controller,
    String label,
    BuildContext context, {
    bool isEditable = true,
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
          const SizedBox(height: 4), // Pequeño espacio entre label y campo
          TextFormField(
            controller: controller,
            readOnly: !isEditable,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 10.0,
              ), // Ajustar padding
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).cardColor, // Color de fondo del campo, adaptable
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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
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

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class NotificationsScreenPatient extends StatefulWidget {
  @override
  _NotificationsScreenPatientState createState() =>
      _NotificationsScreenPatientState();
}

class _NotificationsScreenPatientState
    extends State<NotificationsScreenPatient> {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  bool _receiveNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
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
      // Eliminado BottomAppBar redundante
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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
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

class AppearanceScreenPatient extends StatefulWidget {
  @override
  _AppearanceScreenPatientState createState() =>
      _AppearanceScreenPatientState();
}

class _AppearanceScreenPatientState extends State<AppearanceScreenPatient> {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  String _selectedTheme = 'system';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Apariencia',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
            _buildThemeOption('Tema del sistema', 'system', context),
            _buildThemeOption('Tema claro', 'light', context),
            _buildThemeOption('Tema oscuro', 'dark', context),
            const SizedBox(height: 20),
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
      // Eliminado BottomAppBar redundante
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
        // TODO: Para cambiar el tema real de la app, necesitas un ThemeCubit o Provider
        // que envuelva MaterialApp en main.dart y que escuche estos cambios.
        // Ejemplo con Provider: context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);
        // Ejemplo con BLoC: context.read<ThemeBloc>().add(ThemeChanged(themeMode: ThemeMode.dark));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulando cambio de tema a: $title')),
        );
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
                  SnackBar(content: Text('Simulando cambio de tema a: $title')),
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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
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

class LanguageScreenPatient extends StatefulWidget {
  @override
  _LanguageScreenPatientState createState() => _LanguageScreenPatientState();
}

class _LanguageScreenPatientState extends State<LanguageScreenPatient> {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  String _selectedLanguage = 'es';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Idioma',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
            _buildLanguageOption('Español', 'es', context),
            _buildLanguageOption('Inglés', 'en', context),
            const SizedBox(height: 20),
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
      // Eliminado BottomAppBar redundante
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
        // TODO: Para cambiar el idioma real de la app, necesitas un mecanismo de localización
        // (ej. flutter_localizations, un LocalizationCubit/Provider) que actualice el Locale de MaterialApp.
        // Ejemplo: context.read<LocalizationCubit>().changeLanguage(Locale(langCode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulando cambio de idioma a: $title')),
        );
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
                  SnackBar(
                    content: Text('Simulando cambio de idioma a: $title'),
                  ),
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
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
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
