// lib/presentation/shared/views/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Políticas de Privacidad',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(), // Contiene la nueva información de la entidad y alcance
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Información que Recopilamos',
              content: [
                _buildSubsection(
                  subtitle: '1.1 Información Personal',
                  text:
                      'Recopilamos información que usted nos proporciona directamente al crear una cuenta, incluyendo: nombre completo, correo electrónico, número de teléfono, fecha de nacimiento, género, fotografía de perfil y credenciales profesionales (para psicólogos).',
                ),
                _buildSubsection(
                  subtitle: '1.2 Información de Salud',
                  text:
                      'Como plataforma de servicios de salud mental, recopilamos información sensible relacionada con su salud mental, incluyendo: notas de sesiones terapéuticas, diagnósticos, historial clínico, objetivos terapéuticos y cualquier otra información compartida durante las consultas.',
                ),
                _buildSubsection(
                  subtitle: '1.3 Información de Uso',
                  text:
                      'Recopilamos automáticamente información sobre cómo usa la aplicación: registros de acceso, direcciones IP, tipo de dispositivo, sistema operativo, datos de ubicación aproximada y patrones de uso de la aplicación.',
                ),
                _buildSubsection(
                  subtitle: '1.4 Información de Pago',
                  text:
                      'Los datos de pago son procesados de forma segura por nuestros proveedores de pago (Stripe). No almacenamos información completa de tarjetas de crédito en nuestros servidores.',
                ),
              ],
            ),
            _buildSection(
              title: '2. Cómo Usamos su Información',
              content: [
                _buildBulletPoint(
                    'Proporcionar y mejorar nuestros servicios de salud mental'),
                _buildBulletPoint(
                    'Facilitar la comunicación entre pacientes y psicólogos'),
                _buildBulletPoint('Procesar pagos y gestionar citas'),
                _buildBulletPoint(
                    'Cumplir con obligaciones legales y regulatorias'),
                _buildBulletPoint(
                    'Mejorar la seguridad y prevenir fraudes'),
                _buildBulletPoint(
                    'Enviar notificaciones importantes sobre el servicio'),
                _buildBulletPoint(
                    'Realizar análisis agregados y anónimos para mejorar la plataforma'),
              ],
            ),
            _buildSection(
              title: '3. Base Legal para el Procesamiento',
              content: [
                _buildSubsection(
                  subtitle: 'Consentimiento',
                  text:
                      'Al usar nuestra aplicación, usted consiente el procesamiento de sus datos personales y de salud según se describe en esta política.',
                ),
                _buildSubsection(
                  subtitle: 'Ejecución de Contrato',
                  text:
                      'Procesamos sus datos para cumplir con el contrato de servicios entre usted y nuestra plataforma.',
                ),
                _buildSubsection(
                  subtitle: 'Obligaciones Legales',
                  text:
                      'Podemos procesar datos para cumplir con leyes aplicables, como la NOM-004-SSA3-2012 en México.',
                ),
              ],
            ),
            _buildSection(
              title: '4. Compartir Información',
              content: [
                _buildSubsection(
                  subtitle: 'Con Profesionales de la Salud',
                  text:
                      'Los psicólogos registrados tienen acceso a la información necesaria para proporcionar servicios terapéuticos a sus pacientes.',
                ),
                _buildSubsection(
                  subtitle: 'Proveedores de Servicios',
                  text:
                      'Compartimos información con proveedores terceros que nos ayudan a operar la plataforma: Firebase (Google), Stripe (procesamiento de pagos), servicios de hosting y almacenamiento en la nube.',
                ),
                _buildSubsection(
                  subtitle: 'Requerimientos Legales',
                  text:
                      'Podemos divulgar información si es requerido por ley, orden judicial, o para proteger la seguridad de usuarios o terceros.',
                ),
                _buildSubsection(
                  subtitle: 'Nunca Vendemos sus Datos',
                  text:
                      'No vendemos, alquilamos ni comercializamos su información personal o de salud a terceros con fines publicitarios.',
                ),
              ],
            ),
            _buildSection(
              title: '5. Seguridad de Datos',
              content: [
                _buildBulletPoint(
                    'Encriptación de datos en tránsito y en reposo'),
                _buildBulletPoint('Autenticación segura mediante Firebase Auth'),
                _buildBulletPoint(
                    'Acceso restringido basado en roles (paciente/psicólogo)'),
                _buildBulletPoint('Monitoreo continuo de seguridad'),
                _buildBulletPoint('Auditorías regulares de seguridad'),
                _buildBulletPoint('Copias de seguridad automáticas'),
                _buildSubsection(
                  subtitle: '',
                  text:
                      'Sin embargo, ningún método de transmisión por Internet es 100% seguro. Aunque implementamos medidas de seguridad razonables, no podemos garantizar la seguridad absoluta.',
                ),
              ],
            ),
            _buildSection(
              title: '6. Sus Derechos',
              content: [
                _buildSubsection(
                  subtitle: 'Derechos ARCO',
                  text:
                      'Conforme a la Ley Federal de Protección de Datos Personales en Posesión de Particulares (LFPDPPP), usted tiene derecho a:',
                ),
                _buildBulletPoint(
                    'Acceder a sus datos personales que poseemos'),
                _buildBulletPoint(
                    'Rectificar datos inexactos o incompletos'),
                _buildBulletPoint(
                    'Cancelar (eliminar) sus datos cuando considere que no son necesarios'),
                _buildBulletPoint(
                    'Oponerse al tratamiento de sus datos para fines específicos'),
                _buildSubsection(
                  subtitle: 'Portabilidad de Datos',
                  text:
                      'Puede solicitar una copia de sus datos en formato estructurado y legible.',
                ),
                _buildSubsection(
                  subtitle: 'Revocación del Consentimiento',
                  text:
                      'Puede revocar su consentimiento en cualquier momento, aunque esto puede limitar su acceso a ciertos servicios.',
                ),
                _buildSubsection(
                  subtitle: 'Ejercicio de Derechos',
                  text:
                      'Para ejercer estos derechos, contacte a: contacto@teteocan.com',
                ),
              ],
            ),
            _buildSection(
              title: '7. Retención de Datos',
              content: [
                _buildBulletPoint(
                    'Datos de cuenta: mientras su cuenta esté activa'),
                _buildBulletPoint(
                    'Historiales clínicos: mínimo 5 años según NOM-004-SSA3-2012'),
                _buildBulletPoint(
                    'Datos de pago: según requisitos fiscales (generalmente 5 años)'),
                _buildBulletPoint(
                    'Registros de auditoría: hasta 7 años para cumplimiento legal'),
                _buildBulletPoint(
                    'La retención total de datos personales es por el tiempo necesario para cumplir con las finalidades y 2 años después de la terminación contractual.'),
                _buildSubsection(
                  subtitle: '',
                  text:
                      'En el caso de datos sensibles (estado emocional, interacciones con IA o psicólogos), estos se conservarán únicamente el tiempo indispensable para el seguimiento terapéutico y serán eliminados o anonimizados de manera segura una vez cumplida su finalidad. Después de estos períodos, los datos son eliminados de forma segura o anonimizados para análisis estadísticos.',
                ),
              ],
            ),
            _buildSection(
              title: '8. Menores de Edad',
              content: [
                _buildSubsection(
                  subtitle: '',
                  text:
                      'Nuestra plataforma está diseñada para usuarios mayores de 18 años. Si un menor requiere servicios, debe contar con el consentimiento expreso de un padre o tutor legal. Los datos de menores reciben protecciones adicionales según la legislación aplicable.',
                ),
              ],
            ),
            _buildSection(
              title: '9. Transferencias Internacionales',
              content: [
                _buildSubsection(
                  subtitle: '',
                  text:
                      'Sus datos pueden ser transferidos y procesados en servidores ubicados fuera de México, particularmente en Estados Unidos (Firebase/Google Cloud). Estas transferencias cumplen con las cláusulas contractuales estándar y medidas de seguridad apropiadas, asegurando que el receptor brinde un nivel de protección equivalente al exigido por la LFPDPPP en México.',
                ),
              ],
            ),
            _buildSection(
              title: '10. Cookies y Tecnologías Similares',
              content: [
                _buildBulletPoint(
                    'Cookies esenciales: necesarias para el funcionamiento de la app'),
                _buildBulletPoint(
                    'Cookies analíticas: para entender cómo usa la aplicación'),
                _buildBulletPoint(
                    'Cookies de preferencias: para recordar sus configuraciones'),
                _buildSubsection(
                  subtitle: '',
                  text:
                      'Puede gestionar las preferencias de cookies en la configuración de su dispositivo.',
                ),
              ],
            ),
            _buildSection(
              title: '11. Cambios a esta Política',
              content: [
                _buildSubsection(
                  subtitle: '',
                  text:
                      'Podemos actualizar esta política de privacidad periódicamente. Le notificaremos sobre cambios significativos mediante correo electrónico o notificación en la aplicación. La fecha de la última actualización se indica al inicio de este documento.',
                ),
              ],
            ),
            _buildSection(
              title: '12. Contacto',
              content: [
                _buildSubsection(
                  subtitle: 'Responsable de Datos',
                  text: 'Teteocan Technologies S.A.S. de C.V.',
                ),
                _buildSubsection(
                  subtitle: 'Dirección',
                  text: 'Cuautitlán Izcalli, Estado de México, México',
                ),
                _buildSubsection(
                  subtitle: 'Email',
                  text: 'contacto@teteocan.com',
                ),
                _buildSubsection(
                  subtitle: 'Teléfono',
                  text: '6451157016',
                ),
                _buildSubsection(
                  subtitle: 'Horario de Atención',
                  text: 'Lunes a Viernes, 9:00 AM - 6:00 PM (Hora del Centro de México)',
                ),
              ],
            ),
            _buildSection(
              title: '13. Uso de la IA',
              content: [
                _buildSubsection(
                  subtitle: '',
                  text:
                      'Aurora IA utiliza algoritmos de inteligencia artificial con fines de acompañamiento emocional. La IA no sustituye un diagnóstico, tratamiento médico ni atención psicológica de emergencia. En caso de crisis, el usuario será redirigido a líneas de apoyo oficiales.',
                ),
              ],
            ),
            _buildSection(
              title: '14. Información Específica para Psicólogos',
              content: [
                _buildSubsection(
                  subtitle: 'Confidencialidad Profesional',
                  text:
                      'Los psicólogos deben mantener la confidencialidad según el Código Ético del Psicólogo y la NOM-025-SSA2-2014.',
                ),
                _buildSubsection(
                  subtitle: 'Responsabilidad Profesional',
                  text:
                      'Los psicólogos son responsables del uso ético y legal de la información de sus pacientes.',
                ),
                _buildSubsection(
                  subtitle: 'Límites de Confidencialidad',
                  text:
                      'La confidencialidad puede romperse en casos de riesgo inmediato de daño a sí mismo o a terceros, o cuando sea requerido por ley.',
                ),
              ],
            ),
            _buildSection(
              title: '15. Cumplimiento Normativo',
              content: [
                _buildSubsection(
                  subtitle: '',
                  text:
                      'Esta política cumple con las siguientes normativas mexicanas:',
                ),
                _buildBulletPoint(
                    'Ley Federal de Protección de Datos Personales en Posesión de Particulares (LFPDPPP)'),
                _buildBulletPoint('NOM-004-SSA3-2012 del expediente clínico'),
                _buildBulletPoint(
                    'NOM-025-SSA2-2014 para la prestación de servicios de salud en unidades de atención integral hospitalaria médico-psiquiátrica'),
                _buildBulletPoint('Código Ético del Psicólogo'),
                _buildBulletPoint('Ley General de Salud'),
              ],
            ),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // --- FUNCIÓN ACTUALIZADA CON LA INFORMACIÓN ESPECÍFICA ---
    final introTextStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[800],
      fontFamily: 'Poppins',
      height: 1.5,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: AppConstants.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aviso de Privacidad',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Última actualización: ${_getCurrentDate()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          // 1. Entidad y Responsabilidad
          Text(
            'Aurora: AI Therapy es un producto desarrollado y operado por Teteocan Technologies S.A.S. de C.V., con domicilio en Cuautitlán Izcalli, Estado de México, México, quien es responsable del tratamiento de sus datos personales conforme a la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP).',
            style: introTextStyle,
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          // 2. Referencias y Alcance (AURORA IA)
          Text(
            'Las referencias a "AURORA IA: THERAPY" en este Aviso se refieren a TETEOCAN TECHNOLOGIES de México, S.A.S de C.V. y a cualquier empresa directa o indirectamente de su propiedad y/o controlada por tal sociedad o que esté bajo un controlante común, con la que usted esté interactuando o con la que tenga una relación comercial (en adelante, "AURORA IA").',
            style: introTextStyle,
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          // 3. Alcance de Marketing
          Text(
            'Este Aviso de Privacidad también se aplica al contenido de marketing de Aurora IA, incluidas las recomendaciones, promociones, campañas informativas y anuncios relacionados con nuestros servicios de acompañamiento emocional y sesiones psicológicas, que nosotros (o un proveedor de servicios que actúe en nuestro nombre) podamos enviarle en sitios web, plataformas o aplicaciones de terceros, con base en su interacción y uso de la aplicación. Dichos sitios web o aplicaciones de terceros cuentan generalmente con su propio Aviso de Privacidad y Términos y Condiciones, por lo que le recomendamos revisarlos antes de utilizarlos.',
            style: introTextStyle,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  // --- El resto de las funciones auxiliares se mantienen iguales ---
  Widget _buildSection({
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        ...content,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubsection({
    required String subtitle,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty) ...[
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Importante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Al continuar usando nuestra aplicación, usted reconoce que ha leído, entendido y acepta los términos de este Aviso de Privacidad. Si no está de acuerdo con alguna parte de esta política, por favor absténgase de usar nuestros servicios.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontFamily: 'Poppins',
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${now.day} de ${months[now.month - 1]} de ${now.year}';
  }
}