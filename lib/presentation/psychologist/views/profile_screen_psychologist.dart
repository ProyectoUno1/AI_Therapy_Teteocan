// lib/presentation/psychologist/views/profile_screen_psychologist.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/profile_list_item.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/professional_info_setup_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/privacy_policy_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_reviews_screen_psychologist.dart ';
import 'package:ai_therapy_teteocan/presentation/theme/views/theme_settings_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/support_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/bank_info_screen.dart';

class ProfileScreenPsychologist extends StatefulWidget {
  const ProfileScreenPsychologist({super.key});
  @override
  _ProfileScreenPsychologistState createState() =>
      _ProfileScreenPsychologistState();
}

class _ProfileScreenPsychologistState extends State<ProfileScreenPsychologist> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),

          // Header con información del psicólogo
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String userName = 'Cargando...';
              String userEmail = '';
              String professionalTitle = '';
              String? profileImageUrl;

              if (authState.status == AuthStatus.authenticated &&
                  authState.psychologist != null) {
                userName = authState.psychologist!.username;
                userEmail = authState.psychologist!.email;
                professionalTitle =
                    authState.psychologist!.professionalTitle ?? 'Psicólogo/a';
                profileImageUrl = authState.psychologist!.profilePictureUrl;
              }

              return Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 250,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                          child: profileImageUrl != null
                              ? Image.network(
                                  profileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                        ),
                        Expanded(
                          child: Padding(
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
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  professionalTitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  userEmail,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 12,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          builder: (context) =>
                              PersonalInfoScreenPsychologist(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Sección Perfil Profesional
          Text(
            'Perfil Profesional',
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
                  icon: Icons.work_outline,
                  text: 'Información profesional',
                  secondaryText: 'Editar perfil',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProfessionalInfoSetupScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                ProfileListItem(
                  icon: Icons.star_outline,
                  text: 'Reseñas',
                  secondaryText: 'Ver calificaciones',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PsychologistReviewsScreenPsychologist(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección Cuenta
          Text(
            'Cuenta',
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
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'Información de pagos',
                  secondaryText: 'Gestionar cobros',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BankInfoScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección Configuración
          Text(
            'Configuración',
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
                  icon: Icons.palette_outlined,
                  text: 'Apariencia',
                  secondaryText: 'Tema y colores',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSettingsScreen(),
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
                  icon: Icons.language_outlined,
                  text: 'Idioma',
                  secondaryText: 'Español',
                  onTap: () {
                    // TODO: Implementar pantalla de idioma
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad próximamente'),
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
                  icon: Icons.help_outline,
                  text: 'Soporte',
                  secondaryText: 'Ayuda y contacto',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SupportScreen(userType: 'psychologist'),
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
                  icon: Icons.policy_outlined,
                  text: 'Política de privacidad',
                  secondaryText: 'Términos y condiciones',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Botón de cerrar sesión
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.unauthenticated &&
                  !Navigator.of(context).canPop()) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                height: 48,
                child: ElevatedButton(
                  onPressed: state.status == AuthStatus.loading
                      ? null
                      : () {
                          _showLogoutConfirmationDialog(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: state.status == AuthStatus.loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red.shade700,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout,
                              size: 18,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
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

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PersonalInfoScreenPsychologist extends StatelessWidget {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

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
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      String? profileImageUrl;

                      if (authState.status == AuthStatus.authenticated &&
                          authState.psychologist != null) {
                        profileImageUrl =
                            authState.psychologist!.profilePictureUrl;
                      }

                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: lightAccentColor,
                        backgroundImage:
                            profileImageUrl != null &&
                                profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child:
                            profileImageUrl == null || profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
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
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              label: const Text(
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
              icon: const Icon(Icons.help_outline, color: Colors.white),
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

class ProfessionalInfoScreenPsychologist extends StatelessWidget {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información Profesional',
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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: lightAccentColor,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
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
            const SizedBox(height: 30),
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
            const SizedBox(height: 10),
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
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              label: const Text(
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
              icon: const Icon(Icons.help_outline, color: Colors.white),
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

class NotificationsScreenPsychologist extends StatefulWidget {
  @override
  _NotificationsScreenPsychologistState createState() =>
      _NotificationsScreenPsychologistState();
}

class _NotificationsScreenPsychologistState
    extends State<NotificationsScreenPsychologist> {
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
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              label: const Text(
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
              icon: const Icon(Icons.help_outline, color: Colors.white),
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

class AppearanceScreenPsychologist extends StatefulWidget {
  @override
  _AppearanceScreenPsychologistState createState() =>
      _AppearanceScreenPsychologistState();
}

class _AppearanceScreenPsychologistState
    extends State<AppearanceScreenPsychologist> {
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
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              label: const Text(
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
              icon: const Icon(Icons.help_outline, color: Colors.white),
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

class LanguageScreenPsychologist extends StatefulWidget {
  @override
  _LanguageScreenPsychologistState createState() =>
      _LanguageScreenPsychologistState();
}

class _LanguageScreenPsychologistState
    extends State<LanguageScreenPsychologist> {
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
      bottomNavigationBar: BottomAppBar(
        color: accentColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              label: const Text(
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
              icon: const Icon(Icons.help_outline, color: Colors.white),
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
