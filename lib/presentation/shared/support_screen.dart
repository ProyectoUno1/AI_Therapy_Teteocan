// lib/presentation/shared/support_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/contact_form_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/faq_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/my_tickets_screen.dart';

class SupportScreen extends StatefulWidget {
  final String userType; // 'patient' o 'psychologist'

  const SupportScreen({super.key, required this.userType});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = context.read<AuthBloc>().state;

    // Obtener nombre del usuario según el tipo
    String userName = 'Usuario';
    if (authState.patient != null) {
      userName = authState.patient!.username;
    } else if (authState.psychologist != null) {
      userName =
          authState.psychologist!.fullName ?? authState.psychologist!.username;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Contáctanos',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con saludo
            _buildWelcomeHeader(userName),
            const SizedBox(height: 32),

            // Sección "¿Cómo podemos ayudarte?"
            _buildHelpSection(isDarkMode),
            const SizedBox(height: 32),

            // Línea divisoria
            Divider(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              height: 1,
            ),
            const SizedBox(height: 32),

            // Información de contacto
            _buildContactInfo(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $userName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Estamos aquí para ayudarte',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo podemos ayudarte?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 20),

        // Primera fila de opciones
        Row(
          children: [
            Expanded(
              child: _buildHelpOption(
                icon: Icons.email_outlined,
                title: 'Enviar mensaje',
                subtitle: 'Contáctanos directamente',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ContactFormScreen(userType: widget.userType),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildHelpOption(
                icon: Icons.help_outline,
                title: 'Preguntas frecuentes',
                subtitle: 'Respuestas rápidas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FAQScreen(userType: widget.userType),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Segunda fila de opciones
        Row(
          children: [
            Expanded(
              child: _buildHelpOption(
                icon: Icons.confirmation_number_outlined,
                title: 'Mis tickets',
                subtitle: 'Ver solicitudes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyTicketsScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 16),
           
          ],
        ),
      ],
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de contacto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 20),

        // Email
        _buildContactItem(
          icon: Icons.email_outlined,
          title: 'Email',
          value: 'soporte@aurora.com',
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        // Teléfono
        _buildContactItem(
          icon: Icons.phone_outlined,
          title: 'Teléfono',
          value: '+52 55 1234 5678',
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        // Ubicación
        _buildContactItem(
          icon: Icons.location_on_outlined,
          title: 'Ubicación',
          value: 'Ciudad de México, México',
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppConstants.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Funcionalidad en desarrollo',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}