// lib/presentation/shared/faq_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/support_ticket_model.dart';

class FAQScreen extends StatefulWidget {
  final String userType;

  const FAQScreen({super.key, required this.userType});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<FAQ> _patientFAQs = [
    FAQ(
      question: '¿Cómo puedo agendar una cita con un psicólogo?',
      answer:
          'Desde la pantalla principal, toca el ícono de "Agendar cita" y podrás ver la lista de psicólogos disponibles. Selecciona un psicólogo, elige una fecha y hora disponible, y confirma tu cita.',
      category: 'appointments',
      tags: ['citas', 'agendar', 'psicólogo'],
    ),
    FAQ(
      question: '¿Puedo cancelar o reagendar una cita?',
      answer:
          'Sí, puedes cancelar o reagendar una cita desde la sección "Mis Citas". Ten en cuenta que debes hacerlo con al menos 24 horas de anticipación.',
      category: 'appointments',
      tags: ['cancelar', 'reagendar', 'citas'],
    ),
    FAQ(
      question: '¿Cómo funciona el chat con mi psicólogo?',
      answer:
          'Una vez que tengas una cita confirmada, podrás acceder al chat desde la sección "Mis Citas". El chat está disponible durante el horario de tu sesión.',
      category: 'chat',
      tags: ['chat', 'mensajes', 'comunicación'],
    ),
    FAQ(
      question: '¿Qué es el límite de mensajes con la IA?',
      answer:
          'Los usuarios gratuitos tienen un límite de 5 mensajes diarios con la IA de apoyo. Los usuarios premium tienen acceso ilimitado. Este límite se reinicia cada 24 horas.',
      category: 'account',
      tags: ['IA', 'límite', 'premium', 'mensajes'],
    ),
    FAQ(
      question: '¿Cómo actualizo mi información de perfil?',
      answer:
          'Ve a tu perfil tocando tu foto en la esquina superior derecha. Desde ahí puedes editar tu información personal, foto de perfil, y otros datos.',
      category: 'account',
      tags: ['perfil', 'editar', 'información'],
    ),
    FAQ(
      question: '¿Los pagos son seguros?',
      answer:
          'Sí, utilizamos Stripe como procesador de pagos, que cumple con los más altos estándares de seguridad (PCI DSS). Nunca almacenamos tu información de tarjeta en nuestros servidores.',
      category: 'billing',
      tags: ['pagos', 'seguridad', 'stripe'],
    ),
    FAQ(
      question: '¿Qué incluye la membresía premium?',
      answer:
          'La membresía premium incluye: mensajes ilimitados con la IA, prioridad en el agendamiento de citas, acceso a recursos exclusivos, y descuentos en sesiones con psicólogos.',
      category: 'billing',
      tags: ['premium', 'membresía', 'beneficios'],
    ),
    FAQ(
      question: '¿Mis datos están protegidos?',
      answer:
          'Absolutamente. Cumplimos con GDPR y leyes de protección de datos. Toda tu información está encriptada y solo tu psicólogo asignado puede acceder a tus registros clínicos.',
      category: 'privacy',
      tags: ['privacidad', 'datos', 'seguridad'],
    ),
    FAQ(
      question: '¿Puedo cambiar de psicólogo?',
      answer:
          'Sí, puedes elegir un psicólogo diferente en cualquier momento. Ve a la sección de "Buscar Psicólogo" y selecciona uno nuevo.',
      category: 'appointments',
      tags: ['cambiar', 'psicólogo', 'elegir'],
    ),
    FAQ(
      question: '¿La app funciona en modo offline?',
      answer:
          'Algunas funciones básicas están disponibles sin conexión, como ver tus citas agendadas y recursos guardados. Sin embargo, necesitas conexión para chat, agendar citas y usar la IA.',
      category: 'technical',
      tags: ['offline', 'conexión', 'internet'],
    ),
  ];

  final List<FAQ> _psychologistFAQs = [
    FAQ(
      question: '¿Cómo configuro mi disponibilidad?',
      answer:
          'Ve a tu perfil y selecciona "Configurar horarios". Ahí podrás establecer tus días y horarios disponibles para consultas.',
      category: 'appointments',
      tags: ['horarios', 'disponibilidad', 'configurar'],
    ),
    FAQ(
      question: '¿Cómo acepto o rechazo citas?',
      answer:
          'Recibirás notificaciones de nuevas solicitudes de cita. Puedes aceptarlas o rechazarlas desde la sección "Solicitudes Pendientes" en tu panel.',
      category: 'appointments',
      tags: ['citas', 'aceptar', 'rechazar'],
    ),
    FAQ(
      question: '¿Puedo ver el historial de mis pacientes?',
      answer:
          'Sí, desde la sección "Mis Pacientes" puedes ver el historial completo de sesiones, notas clínicas y registros de cada paciente.',
      category: 'patients',
      tags: ['historial', 'pacientes', 'registros'],
    ),
    FAQ(
      question: '¿Cómo funcionan los pagos?',
      answer:
          'Los pagos se procesan automáticamente cuando un paciente completa una cita. Los fondos se transfieren a tu cuenta bancaria cada 2 semanas.',
      category: 'billing',
      tags: ['pagos', 'transferencias', 'dinero'],
    ),
    FAQ(
      question: '¿Puedo establecer diferentes tarifas?',
      answer:
          'Sí, puedes configurar diferentes tarifas según el tipo de sesión (individual, pareja, etc.) desde tu perfil profesional.',
      category: 'billing',
      tags: ['tarifas', 'precios', 'configurar'],
    ),
    FAQ(
      question: '¿Qué información de pacientes puedo ver?',
      answer:
          'Puedes acceder a información de contacto, historial de sesiones, notas clínicas, y datos relevantes para el tratamiento. Todo bajo estricta confidencialidad.',
      category: 'privacy',
      tags: ['información', 'pacientes', 'confidencialidad'],
    ),
    FAQ(
      question: '¿Cómo manejo emergencias fuera de horario?',
      answer:
          'Para emergencias fuera de horario, los pacientes son redirigidos a líneas de crisis 24/7. No se espera que estés disponible fuera de tus horarios configurados.',
      category: 'appointments',
      tags: ['emergencias', 'crisis', 'horario'],
    ),
    FAQ(
      question: '¿Puedo actualizar mi perfil profesional?',
      answer:
          'Sí, puedes actualizar tu especialidad, experiencia, educación, certificaciones y foto de perfil en cualquier momento desde "Editar Perfil".',
      category: 'account',
      tags: ['perfil', 'editar', 'actualizar'],
    ),
    FAQ(
      question: '¿Cómo funcionan las videollamadas?',
      answer:
          'Las videollamadas se activan automáticamente durante el horario de la cita. Tanto tú como el paciente recibirán un enlace para unirse.',
      category: 'technical',
      tags: ['videollamadas', 'sesiones', 'tecnología'],
    ),
    FAQ(
      question: '¿Qué hago si un paciente no asiste?',
      answer:
          'Puedes marcar la cita como "No asistió" desde tu panel. El sistema registrará la inasistencia y aplicará las políticas correspondientes.',
      category: 'appointments',
      tags: ['inasistencia', 'no show', 'citas'],
    ),
  ];

  List<String> get _categories => [
    'all',
    'appointments',
    'account',
    'billing',
    if (widget.userType == 'psychologist') 'patients',
    'privacy',
    'technical',
    if (widget.userType == 'patient') 'chat',
  ];

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'all':
        return 'Todas';
      case 'appointments':
        return 'Citas';
      case 'account':
        return 'Cuenta';
      case 'billing':
        return 'Pagos';
      case 'patients':
        return 'Pacientes';
      case 'privacy':
        return 'Privacidad';
      case 'technical':
        return 'Técnico';
      case 'chat':
        return 'Chat';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all':
        return Icons.all_inclusive;
      case 'appointments':
        return Icons.calendar_today;
      case 'account':
        return Icons.person;
      case 'billing':
        return Icons.payment;
      case 'patients':
        return Icons.people;
      case 'privacy':
        return Icons.lock;
      case 'technical':
        return Icons.settings;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.help;
    }
  }

  List<FAQ> get _filteredFAQs {
    List<FAQ> faqs = widget.userType == 'patient'
        ? _patientFAQs
        : _psychologistFAQs;

    if (_selectedCategory != 'all') {
      faqs = faqs.where((faq) => faq.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      faqs = faqs.where((faq) {
        return faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query) ||
            faq.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return faqs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Preguntas Frecuentes',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar pregunta...',
                hintStyle: const TextStyle(fontFamily: 'Poppins'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Categorías
          Container(
            height: 50,
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : (isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getCategoryLabel(category),
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode
                                        ? Colors.white70
                                        : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Lista de FAQs
          Expanded(
            child: _filteredFAQs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron preguntas',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            color: isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta con otros términos de búsqueda',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFAQs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFAQs[index];
                      return _FAQCard(faq: faq, isDarkMode: isDarkMode);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FAQCard extends StatefulWidget {
  final FAQ faq;
  final bool isDarkMode;

  const _FAQCard({required this.faq, required this.isDarkMode});

  @override
  State<_FAQCard> createState() => _FAQCardState();
}

class _FAQCardState extends State<_FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: widget.isDarkMode ? 0 : 2,
      child: InkWell(
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: widget.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppConstants.primaryColor,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.faq.answer,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                if (widget.faq.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.faq.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}