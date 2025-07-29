import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart'; 
import 'package:ai_therapy_teteocan/presentation/shared/profile_list_item.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';



class ProfileScreenPatient extends StatefulWidget {

  const ProfileScreenPatient({super.key});
  @override
  _ProfileScreenPatientState createState() => _ProfileScreenPatientState();
  
}

class _ProfileScreenPatientState extends State<ProfileScreenPatient> {
  // Colores de tu paleta
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;
  final Color warningColor = AppConstants
      .warningColor; 
      

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const SizedBox(height: 30),  
          
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String userName =
                  'Alan Rodriguez';
              String userEmail = 'Alan16@gmail.com'; 
              String profileImageUrl =
                  'https://picsum.photos/seed/768/600';
             

              return Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, 
                children: [
                  
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 56, 
                        height: 56, 
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                      ),
                      // Nombre y Email
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          12,
                          0,
                          0,
                          0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight
                                        .bold, 
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                            ),
                            Text(
                              userEmail,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).hintColor, 
                                    fontSize: 14,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalInfoScreenPatient(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24), 
          
          Text(
            'Account', 
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).cardColor, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).dividerColor.withOpacity(0.5), 
              ),
            ),
            child: Column(
              children: [
              
                ProfileListItem(
                  icon:
                      Icons.military_tech_outlined, 
                  text:
                      'Suscripción', 
                  secondaryText: 'Aurora Premium',
                  onTap: () {
                    
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.credit_card_outlined, 
                  text: 'Pagos',
                  secondaryText: 'N/A',
                  onTap: () {
                   //logica para pagos
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          
          Text(
            'Notifications', 
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
                _buildNotificationToggle(
                  'Notificaciones Pop-up', 
                  Icons.notifications_none,
                  true,
                  (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pop-up Notificaciones: $value')),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                _buildNotificationToggle(
                  'Notificaciones por Email', 
                  Icons.mail_outline,
                  true,
                  (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notificaciones por Email: $value'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

         
          Text(
            'Other', 
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
                  icon: Icons
                      .settings_outlined, 
                  text: 'Configuración', 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreenPatient(),
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
                  icon: Icons.contact_support_outlined,
                  text: 'Contactanos', 
                  onTap: () {
                    /* Lógica para Contactanos */
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.privacy_tip_outlined,
                  text:
                      'Politicas de Privacidad',
                  onTap: () {
                    /* Lógica para Politicas de Privacidad */
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

  Widget _buildSectionContainer(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
            ),
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
          child: Column(mainAxisSize: MainAxisSize.max, children: children),
        ),
      ],
    );
  }

 
  Widget _buildNotificationToggle(
    String title,
    IconData icon,
    bool initialValue,
    ValueChanged<bool> onChanged,
  ) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setStateInternal) {
        bool currentValue = initialValue;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
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
              Switch(
                value: currentValue,
                onChanged: (newValue) {
                  setStateInternal(() {
                    currentValue = newValue;
                  });
                  onChanged(newValue);
                },
                activeColor: accentColor,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ],
          ),
        );
      },
    );
  }

  // Diálogo de confirmación para cerrar sesión
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Sí, Cerrar Sesión',
                style: TextStyle(color: Colors.red, fontFamily: 'Poppins'),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
            ),
          ],
        );
      },
    );
  }
}


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
  final TextEditingController _phoneController = TextEditingController(
    text: '1234567890',
  );

  // Variable para la imagen de perfil seleccionada localmente
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    _trySignOut();

  }
  // Nueva función para intentar cerrar sesión
  Future<void> _trySignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      print('✅ Sesión de Firebase cerrada exitosamente al iniciar RegisterPatientScreen.');
    } catch (e) {
      print('⚠️ Error al intentar cerrar sesión de Firebase: $e');
    }
  }

  // Método para seleccionar una foto de la galería
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
            content: Text('Foto seleccionada. ¡Ahora puedes guardarla!'),
          ),
        );
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
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor,
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
                    onTap: _pickImage,
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
                    'Toca para cambiar foto', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).hintColor,
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
            _buildInputFieldWithLabel(context, _nameController, 'Nombre'),
            _buildInputFieldWithLabel(
              context,
              _dobController,
              'Fecha de nacimiento',
            ),
            _buildInputFieldWithLabel(
              context,
              _phoneController,
              'Número de teléfono',
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Guardando cambios...')),
                  );
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
    );
  }

  Widget _buildInputFieldWithLabel(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool isEditable = true,
    int maxLines = 1,
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
              color: Theme.of(context).hintColor,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            readOnly: !isEditable,
            maxLines: maxLines,
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
              ), 
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ), 
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).cardColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String section, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();
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
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor,
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
                    inactiveTrackColor: Colors.grey.shade300,
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
    );
  }

  void _showHelpDialog(BuildContext context, String section, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class SettingsScreenPatient extends StatefulWidget {
  @override
  _SettingsScreenPatientState createState() => _SettingsScreenPatientState();
}

class _SettingsScreenPatientState extends State<SettingsScreenPatient> {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  String _selectedTheme = 'system';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text(
          'Configuración',
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
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();
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
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, 
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
      builder: (BuildContext dialogContext) {
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
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
