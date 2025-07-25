import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart'; // Para redirigir al cerrar sesión
import 'package:ai_therapy_teteocan/presentation/shared/profile_list_item.dart'; // Tu widget de ítem de lista
import 'package:image_picker/image_picker.dart'; // Importa image_picker
import 'dart:io'; // Para File

// Importaciones de las sub-pantallas
// Asegúrate de que estas clases están definidas en algún lugar accesible,
// ya sea en este mismo archivo o en archivos separados dentro de la misma carpeta
// o en una subcarpeta (ej. 'details/personal_info_screen_patient.dart')
// Para este ejemplo, las mantendré como clases internas para la demo
// o asumiendo que están en archivos separados importables.
// Si las tienes en archivos separados, asegúrate de importarlas.
// Si no existen todavía, las crearé como stubs al final de este archivo.

class ProfileScreenPatient extends StatefulWidget {
  @override
  _ProfileScreenPatientState createState() => _ProfileScreenPatientState();
}

class _ProfileScreenPatientState extends State<ProfileScreenPatient> {
  // Colores de tu paleta
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;
  final Color warningColor = AppConstants
      .warningColor; // Para la tarjeta de suscripción, si decides reintroducirla en este diseño

  @override
  Widget build(BuildContext context) {
    // El AppBar y BottomNavigationBar se manejan en PatientHomeScreen.
    // Este widget es solo el cuerpo de la pestaña de perfil.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0), // Padding general
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Para que la columna se ajuste al contenido
        children: [
          const SizedBox(height: 30), // Espacio superior
          // Sección superior de Perfil (Avatar, Nombre, Email, Botón Edit)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String userName =
                  'Alan Rodriguez'; // Placeholder como en el diseño
              String userEmail = 'Alan16@gmail.com'; // Placeholder
              String profileImageUrl =
                  'https://picsum.photos/seed/768/600'; // Imagen de ejemplo del diseño
              // Si tienes la URL real en authState.user, úsala aquí:
              // if (authState.user != null) {
              //   userName = authState.user!.username;
              //   userEmail = authState.user!.email;
              //   if (authState.user!.profilePictureUrl != null) {
              //     profileImageUrl = authState.user!.profilePictureUrl!;
              //   }
              // }

              return Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Distribuye el espacio
                children: [
                  // Avatar y Texto de Perfil
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 56, // Ancho de 56 para el avatar
                        height: 56, // Alto de 56 para el avatar
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
                        ), // Espacio entre imagen y texto
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight
                                        .bold, // Bold como en el diseño
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
                                    ).hintColor, // Color secundario para el email
                                    fontSize: 14,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Flecha a la derecha para navegar a "Información Personal"
                  // Esta flecha es opcional si el "Información personal" en la sección de "Account" ya cumple la función.
                  // Si quieres mantenerla como en el diseño de FlutterFlow para una navegación rápida, aquí está.
                  // Por ahora, la mantengo para replicar el diseño de la imagen original del usuario.
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
          const SizedBox(height: 24), // Espacio después del encabezado
          // Sección "Account" (Configuración del Perfil)
          Text(
            'Account', // Título de la sección como en el diseño
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
                // Adaptado del ejemplo de FlutterFlow
                ProfileListItem(
                  icon:
                      Icons.military_tech_outlined, // Icono de "Member Status"
                  text:
                      'Suscripción', // Cambiado a "Suscripción" según tu solicitud
                  secondaryText: 'Aurora Premium',
                  onTap: () {
                    /* Lógica para Suscripción */
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.credit_card_outlined, // Icono de "My Transaction"
                  text: 'Pagos', // Cambiado a "Pagos" según tu solicitud
                  secondaryText: 'N/A',
                  onTap: () {
                    /* Lógica para Pagos */
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sección "Notifications" (como en el diseño con toggles)
          Text(
            'Notifications', // Título de la sección
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
                  'Notificaciones Pop-up', // Texto actualizado
                  Icons.notifications_none,
                  true, // Valor inicial (puedes conectarlo a un estado real)
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
                  'Notificaciones por Email', // Texto actualizado
                  Icons.mail_outline,
                  true, // Valor inicial
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

          // Sección "Other" (General)
          Text(
            'Other', // Título de la sección
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
                      .settings_outlined, // Usamos 'Settings' como en el ejemplo
                  text: 'Configuración', // Cambiado a "Configuración"
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreenPatient(),
                      ),
                    ); // Redirige a SettingsScreen
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.contact_support_outlined,
                  text: 'Contactanos', // Cambiado a "Contactanos"
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
                      'Politicas de Privacidad', // Cambiado a "Politicas de Privacidad"
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

  // Widget auxiliar para los contenedores de sección (Account, Notifications, Other)
  // Este widget ahora es redundante para el cuerpo principal de ProfileScreenPatient
  // porque el diseño se construye directamente, pero se mantiene si se usa en otro lugar.
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

  // Widget para toggles de notificación adaptado al diseño
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
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        );
      },
    );
  }
}

// --- Sub-pantallas del perfil del paciente (actualizadas con los cambios y renombradas) ---

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

  // Variable para la imagen de perfil seleccionada localmente
  File? _profileImageFile;

  @override
  void initState() {
    super.initState();
    // Aquí podrías cargar la información real del usuario desde un BLoC/Cubit
    // Por ejemplo: context.read<UserProfileCubit>().loadProfile();
    // Y actualizar los controladores con los datos.
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
        // TODO: Aquí llamarías a un evento de BLoC para subir la imagen al almacenamiento (Firebase Storage)
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
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Adapta el color de fondo al tema
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
                    onTap: _pickImage, // Habilitar la opción de subir foto
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
            // Utilizando el nuevo _buildInputFieldWithLabel con un diseño mejorado
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
    );
  }

  // Widget para construir campos de texto con label arriba y diseño mejorado
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
          const SizedBox(height: 4), // Pequeño espacio entre label y campo
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
              ), // Ajustar padding
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ), // Borde adaptable al tema
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

  bool _receiveNotifications = true; // Estado para el toggle de notificaciones

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Adapta el color de fondo al tema
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

  String _selectedTheme = 'system'; // Estado local para la selección del Radio

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Adapta el color de fondo al tema
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

  String _selectedLanguage = 'es'; // Estado local para la selección del Radio

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Adapta el color de fondo al tema
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
