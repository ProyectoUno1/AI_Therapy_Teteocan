// lib/presentation/shared/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Política de Privacidad',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Última actualización
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.update,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Última actualización: 15 de enero de 2025',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introducción
            _buildSection(
              icon: Icons.privacy_tip,
              title: '1. Introducción',
              content:
                  '''En Aurora, nos comprometemos a proteger tu privacidad y tus datos personales. Esta Política de Privacidad describe cómo recopilamos, usamos, almacenamos y protegemos tu información.

Al usar nuestra aplicación, aceptas las prácticas descritas en esta política. Si no estás de acuerdo, te recomendamos no utilizar nuestros servicios.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.info,
              title: '2. Información que Recopilamos',
              content: '''Recopilamos diferentes tipos de información:

• Información de cuenta: nombre, correo electrónico, fecha de nacimiento, número de teléfono.
• Información profesional (psicólogos): título, licencia, especialidad, experiencia.
• Información de salud: datos relacionados con tus sesiones de terapia, notas clínicas (solo accesibles por tu psicólogo).
• Datos de uso: cómo interactúas con la aplicación, funciones utilizadas, tiempo de uso.
• Información de pago: procesada por Stripe de forma segura (no almacenamos datos de tarjetas).''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.build,
              title: '3. Cómo Usamos Tu Información',
              content: '''Utilizamos tu información para:

• Proporcionar y mejorar nuestros servicios.
• Conectar pacientes con psicólogos adecuados.
• Procesar pagos y gestionar suscripciones.
• Enviar notificaciones importantes sobre tu cuenta y citas.
• Analizar el uso de la aplicación para mejorar la experiencia.
• Cumplir con obligaciones legales y regulatorias.
• Prevenir fraudes y garantizar la seguridad.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.lock,
              title: '4. Protección de Datos de Salud',
              content:
                  '''Tus datos de salud mental son extremadamente sensibles:

• Cumplimos con HIPAA y regulaciones de protección de datos de salud.
• Solo tu psicólogo asignado puede acceder a tus registros clínicos.
• Toda la información está encriptada en tránsito y en reposo.
• Los registros se almacenan en servidores seguros certificados.
• Implementamos controles de acceso estrictos y auditorías regulares.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.share,
              title: '5. Compartir Información',
              content:
                  '''No vendemos tu información personal. Solo compartimos datos cuando:

• Es necesario para proporcionar el servicio (ej: con tu psicólogo).
• Tienes nuestro consentimiento explícito.
• Es requerido por ley o autoridades competentes.
• Es necesario para procesar pagos (con Stripe).
• Se requiere para proteger la seguridad de usuarios o del público.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.cookie,
              title: '6. Cookies y Tecnologías Similares',
              content: '''Usamos cookies y tecnologías similares para:

• Mantener tu sesión activa.
• Recordar tus preferencias.
• Analizar el uso de la aplicación.
• Mejorar la seguridad.

Puedes gestionar las cookies desde la configuración de tu dispositivo.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.account_circle,
              title: '7. Tus Derechos',
              content: '''Tienes derecho a:

• Acceder a tus datos personales.
• Corregir información incorrecta.
• Solicitar la eliminación de tu cuenta y datos.
• Exportar tus datos en formato portable.
• Retirar tu consentimiento en cualquier momento.
• Presentar una queja ante autoridades de protección de datos.

Para ejercer estos derechos, contáctanos a través del soporte.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.storage,
              title: '8. Retención de Datos',
              content: '''Conservamos tu información mientras:

• Tu cuenta esté activa.
• Sea necesario para proporcionar servicios.
• Sea requerido por ley (registros médicos: mínimo 7 años).

Después, eliminamos o anonimizamos tus datos de forma segura.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.child_care,
              title: '9. Menores de Edad',
              content:
                  '''Aurora está destinada a usuarios mayores de 18 años. No recopilamos intencionalmente información de menores sin consentimiento parental. Si descubrimos que un menor proporcionó información sin autorización, la eliminaremos inmediatamente.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.security,
              title: '10. Seguridad',
              content:
                  '''Implementamos medidas técnicas y organizativas robustas:

• Encriptación SSL/TLS para todas las comunicaciones.
• Encriptación AES-256 para datos en reposo.
• Autenticación de dos factores (2FA).
• Auditorías de seguridad regulares.
• Capacitación del personal en protección de datos.
• Controles de acceso basados en roles.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.public,
              title: '11. Transferencias Internacionales',
              content:
                  '''Tus datos pueden ser transferidos a servidores ubicados en diferentes países. Nos aseguramos de que todas las transferencias cumplan con estándares de protección de datos aplicables, incluyendo cláusulas contractuales estándar aprobadas.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.edit,
              title: '12. Cambios a Esta Política',
              content:
                  '''Podemos actualizar esta política periódicamente. Te notificaremos sobre cambios significativos mediante:

• Notificación en la aplicación.
• Correo electrónico.
• Aviso destacado en la pantalla principal.

Te recomendamos revisar esta política regularmente.''',
              isDarkMode: isDarkMode,
            ),

            _buildSection(
              icon: Icons.contact_mail,
              title: '13. Contacto',
              content:
                  '''Si tienes preguntas sobre esta política o sobre cómo manejamos tus datos, contáctanos:

Email: privacy@aurora-therapy.com
Teléfono: +52 (55) 1234-5678
Dirección: Av. Reforma 123, CDMX, México

También puedes usar el formulario de contacto en la sección de Soporte de la aplicación.''',
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: AppConstants.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tu privacidad es nuestra prioridad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cumplimos con GDPR, HIPAA y leyes de protección de datos aplicables.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: isDarkMode ? Colors.white70 : Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
