import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  final String userRole;

  const TermsAndConditionsScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isAccepted = false;
  bool _isLoading = false;

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);

    try {
      context.read<AuthBloc>().add(
            AuthAcceptTermsAndConditions(
              userRole: widget.userRole,
            ),
          );
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aceptar términos: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _declineTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Términos requeridos',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Debes aceptar los términos y condiciones para poder usar la aplicación.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          final isMobile = ResponsiveUtils.isMobile(context);
          
          return Stack(
            children: [
              // Fondo con degradado
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 255, 255, 255),
                      Color.fromARGB(255, 205, 223, 222),
                      Color.fromARGB(255, 147, 213, 207),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: isLandscape
                    ? _buildLandscapeLayout(isMobile)
                    : _buildPortraitLayout(isMobile),
              ),
            ],
          );
        },
      ),
    );
  }

  // Layout para orientación vertical
  Widget _buildPortraitLayout(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Header compacto
            _buildHeader(context, constraints, isMobile, false),

            // Contenido scrolleable
            Expanded(
              child: _buildContent(context, isMobile, false),
            ),

            // Checkbox y botones
            _buildFooter(context, isMobile, false),
          ],
        );
      },
    );
  }

  // Layout para orientación horizontal
  Widget _buildLandscapeLayout(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Columna izquierda: Header + Footer
            SizedBox(
              width: constraints.maxWidth * 0.35,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildHeader(context, constraints, isMobile, true),
                        const Spacer(),
                        _buildFooter(context, isMobile, true),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Columna derecha: Contenido scrolleable
            Expanded(
              child: _buildContent(context, isMobile, true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BoxConstraints constraints, bool isMobile, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 12 : ResponsiveUtils.getHorizontalPadding(context),
        vertical: isLandscape ? 8 : (isMobile ? 16 : 20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: isLandscape 
                ? 32
                : ResponsiveUtils.getIconSize(context, 60),
            color: const Color(0xFF82c4c3),
          ),
          SizedBox(height: isLandscape ? 6 : (constraints.maxHeight * 0.015)),
          Text(
            'Términos y Condiciones',
            style: TextStyle(
              fontSize: isLandscape ? 14 : ResponsiveUtils.getFontSize(context, 22),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isLandscape ? 3 : (constraints.maxHeight * 0.008)),
          Text(
            'Por favor, lee y acepta nuestros términos',
            style: TextStyle(
              fontSize: isLandscape ? 10 : ResponsiveUtils.getFontSize(context, 12),
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getHorizontalPadding(context),
        vertical: isLandscape ? 12 : 0,
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                'Aceptación de términos',
                'El acceso y uso de Aurora IA Therapy implica la aceptación plena y sin reservas de estos Términos y Condiciones. Si no estás de acuerdo con alguno de los puntos establecidos, deberás abstenerte de utilizar la plataforma. En caso de violación de estos términos, Aurora podrá cancelar, revocar, impedir el uso de la app y tomar acción legal conveniente para sus intereses.',
              ),
              _buildSection(
                context,
                'Objetivo de Aurora',
                'Aurora es una plataforma digital diseñada para brindar acompañamiento virtual en el bienestar emocional mediante:\n\n1. Conversaciones interactivas con un asistente virtual basado en IA que ofrece apoyo emocional inmediato.\n\n2. Sesiones virtuales con psicólogos certificados (con cédula profesional y registro de la SEP) que proporcionan orientación profesional remota.\n\nIMPORTANTE: Aurora, su ChatBot y contenidos tienen carácter informativo y de apoyo emocional, pero NO sustituyen un diagnóstico médico, psiquiátrico o psicológico formal. El ChatBot NO está diseñado para atender situaciones de crisis como intentos de suicidio, autolesiones, violencia o emergencias médicas.',
              ),
              _buildSection(
                context,
                'Líneas de Emergencia México',
                '• Emergencia o riesgo: 911\n• Línea de la Vida: 800 911 2000\n• Consejo Ciudadano: (55) 5533 5533\n• Medicina a Distancia: (55) 5132 0909\n• SAPTEL: (55) 5259 8121\n• Locatel (CDMX): 55 5658 1111',
              ),
              _buildSection(
                context,
                'Psicólogos Independientes',
                'Los psicólogos que ofrecen servicios a través de Aurora son profesionales independientes. Aurora NO mantiene relación laboral con ellos. Si decides contratar sus servicios, la relación se entenderá como un acuerdo entre tú y el profesional elegido, siendo tu responsabilidad exclusiva. Aurora actúa únicamente como plataforma de conexión y NO asume responsabilidad por diagnósticos, tratamientos o consecuencias derivadas de la atención brindada.',
              ),
              _buildSection(
                context,
                'Elegibilidad para el uso',
                'a) Edad mínima: Uso permitido únicamente a mayores de 18 años. Menores de edad requieren consentimiento expreso de padres o tutores legales.\n\nb) Menores de edad: Podrán acceder únicamente cuando:\n   • El registro sea realizado por padre, madre o tutor legal\n   • Se otorgue consentimiento informado para atención psicológica\n   • El profesional esté capacitado para atención a menores\n\nEl tutor que autorice el uso asume responsabilidad sobre acceso, uso y seguimiento de servicios.\n\nc) Residencia: Personas residentes en México u otros países donde no esté prohibido el acceso.\n\nd) Aceptación expresa: Al registrarte, garantizas cumplir con estos requisitos y la veracidad de tu información.',
              ),
              _buildSection(
                context,
                'Uso Responsable de la Plataforma',
                'Te comprometes a usar Aurora de manera ética, legal y conforme a principios de buena fe. Prohibiciones específicas:\n\n• NO manipular, alterar, reproducir ni distribuir el software sin autorización\n• NO usurpar identidad de otro usuario\n• NO chatear con Aurora usando frases que fuercen al ChatBot a violar reglas establecidas\n• NO acosar, amenazar, discriminar o dañar a otros usuarios\n• NO suplantar identidades ni proporcionar información falsa\n\nDebes:\n• Hacer de nuestro conocimiento cualquier imprevisto o falla técnica\n• Respetar confidencialidad y privacidad de información\n• Reconocer que Aurora NO sustituye atención médica presencial\n\nEl incumplimiento puede resultar en suspensión/cancelación inmediata de tu cuenta y notificación a autoridades competentes.',
              ),
              _buildSection(
                context,
                'Creación de Perfil o Cuenta',
                'Para acceder a Aurora, debes crear un perfil proporcionando información veraz, completa y actualizada. El usuario declara, bajo protesta de decir verdad, que los datos personales y de contacto proporcionados son auténticos. El uso de información falsa, inexacta o de terceros sin autorización podrá dar lugar a la suspensión o cancelación inmediata de la cuenta, sin perjuicio de las acciones legales que correspondan.\n\n• Eres responsable de la confidencialidad de tu usuario y contraseña\n• Las cuentas son estrictamente personales e intransferibles\n• Prohibido compartir, ceder o vender el acceso a terceros\n• Tus datos serán tratados conforme al Aviso de Privacidad y LFPDPPP',
              ),
              _buildSection(
                context,
                'Suspensión o Cancelación de Cuentas',
                'Aurora se reserva el derecho de suspender o cancelar cualquier cuenta cuando se detecte incumplimiento a los Términos y Condiciones, uso indebido de la plataforma o falsedad en la información proporcionada, sin que ello genere derecho a indemnización o reembolso.',
              ),
              _buildSection(
                context,
                'Paquetes y Planes',
                'Modalidades disponibles:\n\n• Sesión Individual: \$349.00\n• Mensual (4 sesiones): \$999.00 (\$249.75/sesión)\n• Anual Organizaciones (48 sesiones): \$9,699.00 (\$200.00/sesión)\n• Sesión Estudiante (-40%): \$209.40\n\nCondiciones generales:\n• Las suscripciones son personales, no se permite uso grupal\n• Para acceso grupal, contactar: contacto@teteocan.com\n• Las suscripciones se mantienen vigentes mientras no canceles y realices pagos\n• Si eliminas tu perfil, perderás acceso permanente a tu suscripción\n• Las suscripciones NO se pueden transferir entre cuentas',
              ),
              _buildSection(
                context,
                'Vigencia y Cargos',
                'La suscripción se mantiene activa siempre que:\n• No canceles tu suscripción desde la app\n• La forma de pago no sea rechazada\n\nAurora se reserva el derecho de modificar planes y costos notificándote con al menos 30 días naturales previos. Si continúas usando los servicios después del aviso, se entenderá como aceptación al cambio de costo.\n\nImpuestos y gastos de transacción son adicionales al pago de suscripción. El ciclo de facturación transcurre desde que adquieres el plan hasta su culminación.',
              ),
              _buildSection(
                context,
                'Métodos de Pago',
                'Métodos disponibles:\n• Tarjetas de crédito/débito (Visa, MasterCard, American Express)\n• Plataformas de pago electrónico (PayPal, Stripe, MercadoPago)\n• Transferencia bancaria (si está habilitada)\n\nCondiciones:\n• Precios en pesos mexicanos (MXN)\n• Cobro anticipado y recurrente según periodicidad del plan\n• Autorizas cargos automáticos hasta que canceles la suscripción\n• Para factura (CFDI), proporciona datos fiscales a: contacto@teteocan.com',
              ),
              _buildSection(
                context,
                'Política de Reembolsos',
                'Una vez efectuado el pago y activado el plan o confirmada la sesión, NO procede cancelación automática ni reembolso. Debes cancelar el plan en la app ANTES de que venza y sea cobrado nuevamente.\n\nSe podrá solicitar reembolso ÚNICAMENTE cuando:\n• Falla técnica comprobada que impida acceso durante el periodo\n• Cancelación de sesión por psicólogo sin aviso ni reprogramación (3 días)\n• Cobro indebido o error atribuible al sistema de pago\n\nNO se otorgan reembolsos cuando:\n• El usuario no use los servicios durante la vigencia\n• Cancelaciones con menos de 24 horas de anticipación\n• Los servicios hayan sido prestados parcial o totalmente\n• La insatisfacción derive de expectativas personales distintas',
              ),
              _buildSection(
                context,
                'Ausencias/Cancelaciones - USUARIO',
                'Ausencia: No asistencia sin notificación previa. La sesión se considera prestada SIN derecho a reembolso, crédito o reprogramación. Aurora retiene el monto total y el colaborador recibe su ganancia íntegra.\n\nCancelación con 24+ horas: Permite reprogramar sin costo adicional (sujeto a disponibilidad). El monto se transfiere como crédito para sesión futura. El colaborador NO recibe compensación.\n\nCancelación con menos de 24 horas: Se trata como Ausencia.\n\nExcepciones: Casos de fuerza mayor documentados (emergencias médicas con constancia oficial) pueden autorizar reprogramaciones o reembolsos excepcionales a discreción de Aurora.',
              ),
              _buildSection(
                context,
                'Ausencias/Cancelaciones - COLABORADOR',
                'Ausencia: No asistencia sin notificación. La sesión se considera NO prestada. Aurora notifica inmediatamente al usuario ofreciendo reprogramación sin costo o reembolso total. El colaborador NO recibe compensación y será responsable de daños. Al conteo de 3 ausencias se pueden aplicar sanciones: suspensión temporal o terminación del contrato.\n\nCancelación con 24+ horas: Aurora reprograma con otro colaborador disponible sin costo para el usuario. El colaborador NO recibe compensación.\n\nCancelación con menos de 24 horas: Se trata como Ausencia.\n\nEl colaborador debe registrar asistencia en la plataforma antes de cada sesión como prueba de cumplimiento.',
              ),
              _buildSection(
                context,
                'Limitación de Responsabilidad',
                'Aurora NO será responsable de:\n\n• Decisiones personales, médicas o legales tomadas con base en contenidos de la app\n• Autodiagnósticos realizados con información del ChatBot\n• Malinterpretación de conversaciones o recomendaciones de la IA\n• Afectaciones emocionales derivadas de interacción con ChatBot\n• Diagnósticos erróneos, tratamientos o recomendaciones de psicólogos independientes\n• Daños directos, indirectos, incidentales o consecuenciales\n\nAL USAR AURORA, RECONOCES Y ACEPTAS NO EJERCER ACCIÓN LEGAL contra Aurora, sus socios, directivos, empleados, colaboradores o proveedores. Te comprometes a sacar en paz y a salvo a los mencionados de cualquier daño relacionado con especialistas y/o terceros.\n\nLa relación terapéutica con psicólogos independientes es exclusiva entre usuario y profesional, quedando Aurora totalmente exenta de responsabilidad.',
              ),
              _buildSection(
                context,
                'Caso Fortuito o Fuerza Mayor',
                'Aurora NO será responsable por incumplimiento cuando se deba a:\n\n• Fallas en energía eléctrica, telecomunicaciones o internet\n• Desastres naturales (terremotos, inundaciones, huracanes, incendios)\n• Conflictos laborales, bloqueos, huelgas\n• Actos de autoridades que limiten el servicio\n• Ciberataques, incidentes de seguridad, fallas en servidores externos\n• Epidemias, pandemias o emergencias sanitarias\n\nAurora implementa medidas razonables de seguridad pero NO garantiza servicio libre de interrupciones, errores técnicos o fallas de conexión. El uso de la plataforma se realiza bajo tu propia responsabilidad.',
              ),
              _buildSection(
                context,
                'Propiedad Intelectual',
                'Todos los derechos sobre Aurora (software, algoritmos, código fuente, base de datos, diseños, logotipos, marcas, interfaces, contenidos audiovisuales, textos) son propiedad exclusiva de Aurora o sus licenciantes, protegidos por Ley Federal del Derecho de Autor y Ley de Propiedad Industrial.\n\nLicencia limitada: Uso personal, limitado, no exclusivo, intransferible y revocable para fines personales no comerciales.\n\nProhibido:\n• Copiar, reproducir, modificar, distribuir o explotar contenidos sin autorización\n• Descompilar o aplicar ingeniería inversa\n• Usar logotipos, marcas o signos distintivos sin consentimiento escrito\n\nEl uso indebido puede resultar en cancelación inmediata y acciones legales.',
              ),
              _buildSection(
                context,
                'Uso de Inteligencia Artificial',
                'El sistema de IA proporciona acompañamiento emocional mediante conversaciones automatizadas con carácter meramente INFORMATIVO Y DE APOYO.\n\nReconoces que:\n• Las respuestas de IA se basan en patrones de lenguaje, NO son consejo médico/psicológico/legal profesional\n• Los resultados son orientativos, NO son diagnóstico ni tratamiento clínico\n• En emergencias o crisis, se recomendará acudir a líneas de atención o servicios de emergencia\n\nResponsabilidad del usuario:\n• Usar únicamente con fines personales y de acompañamiento\n• NO compartir información falsa, ilícita o sensible innecesaria\n• Reconocer límites de la herramienta y complementar con sesiones de especialistas',
              ),
              _buildSection(
                context,
                'Confidencialidad',
                'Aurora garantiza confidencialidad de información personal y sensible en apego al Aviso de Privacidad y LFPDPPP. Las partes tratarán como confidencial toda información técnica, comercial o de cualquier naturaleza.\n\nInformación confidencial:\n• Datos personales y de contacto\n• Información sensible emocional, psicológica o de salud\n• Conversaciones con ChatBot\n• Registros en diarios emocionales\n• Información de sesiones con psicólogos\n\nExcepciones:\n• Autorización expresa del usuario\n• Mandato judicial o resolución administrativa\n• Proteger vida, integridad o seguridad en riesgo inminente\n• Datos anonimizados para fines estadísticos\n\nLos psicólogos independientes asumen obligación de confidencialidad según normatividad aplicable. La obligación subsiste después de terminar la relación con Aurora.',
              ),
              _buildSection(
                context,
                'Comentarios, Quejas y Sugerencias',
                'Contacto: contacto@teteocan.com\n\nIncluir en tu comunicación:\n• Nombre completo y correo asociado a la cuenta\n• Descripción clara y detallada del asunto\n• Evidencia documental o capturas de pantalla\n\nAurora dará acuse de recibo y responderá en máximo 10 días hábiles. En casos complejos, se informará el tiempo estimado de resolución.\n\nPara quejas sobre psicólogos independientes, Aurora actúa como canal de enlace pero NO asume responsabilidad por la relación profesional.',
              ),
              _buildSection(
                context,
                'Modificaciones a los Términos',
                'Aurora se reserva el derecho de modificar, actualizar o complementar estos Términos en cualquier momento. Los cambios entrarán en vigor una vez publicados en la aplicación o página web oficial.',
              ),
              _buildSection(
                context,
                'Jurisdicción Aplicable',
                'Estos Términos y cualquier controversia se regirán conforme a las leyes de los Estados Unidos Mexicanos.\n\nPara resolución de controversias, las partes se someten expresamente a la jurisdicción de los tribunales competentes del Estado de México, renunciando a cualquier otro fuero.\n\nComo consumidor, tienes derecho de acudir ante la Procuraduría Federal del Consumidor (PROFECO) para defensa de tus derechos conforme a la Ley Federal de Protección al Consumidor.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile, bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 12 : ResponsiveUtils.getHorizontalPadding(context),
        vertical: isLandscape ? 8 : (isMobile ? 16 : 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkbox de aceptación
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 8 : (isMobile ? 10 : 14),
              vertical: isLandscape ? 4 : (isMobile ? 6 : 10),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _isAccepted,
                    onChanged: (value) {
                      setState(() => _isAccepted = value ?? false);
                    },
                    activeColor: const Color(0xFF82c4c3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'He leído y acepto los términos y condiciones',
                    style: TextStyle(
                      fontSize: isLandscape ? 10 : ResponsiveUtils.getFontSize(context, 12),
                      fontFamily: 'Poppins',
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isLandscape ? 8 : (isMobile ? 12 : 16)),

          // Botón de aceptar
          SizedBox(
            width: double.infinity,
            height: isLandscape ? 42 : ResponsiveUtils.getButtonHeight(context),
            child: ElevatedButton(
              onPressed: _isAccepted && !_isLoading ? _acceptTerms : _declineTerms,
              style: ElevatedButton.styleFrom(
                elevation: 4,
                backgroundColor: null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isAccepted
                        ? [const Color(0xFF82c4c3), const Color(0xFF5ca0ac)]
                        : [Colors.grey, Colors.grey],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Aceptar y continuar',
                          style: TextStyle(
                            fontSize: isLandscape ? 12 : ResponsiveUtils.getFontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, 12),
              color: Colors.black54,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}