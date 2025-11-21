// lib/presentation/shared/contact_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/models/support_ticket_model.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ContactFormScreen extends StatefulWidget {
  final String userType;

  const ContactFormScreen({super.key, required this.userType});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'general';
  String _selectedPriority = 'medium';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'general',
      'label': 'Consulta general',
      'icon': Icons.help_outline,
    },
    {
      'value': 'technical',
      'label': 'Problema técnico',
      'icon': Icons.bug_report,
    },
    {'value': 'billing', 'label': 'Facturación', 'icon': Icons.payment},
    {'value': 'account', 'label': 'Mi cuenta', 'icon': Icons.person},
    {'value': 'appointment', 'label': 'Citas', 'icon': Icons.calendar_today},
    {'value': 'feedback', 'label': 'Sugerencia', 'icon': Icons.feedback},
  ];

  static const String baseUrl = 'https://ai-therapy-teteocan.onrender.com/api';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authState = context.read<AuthBloc>().state;

    String userId = '';
    String userEmail = '';
    String userName = '';
    String? authToken;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        authToken = await currentUser.getIdToken();
      } else {
        throw Exception('Usuario no autenticado en Firebase');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error de autenticación. Intenta cerrar sesión y volver a entrar.');
      }
      setState(() => _isSubmitting = false);
      return;
    }

    if (authState.patient != null) {
      userId = authState.patient!.uid;
      userEmail = authState.patient!.email;
      userName = authState.patient!.username;
    } else if (authState.psychologist != null) {
      userId = authState.psychologist!.uid;
      userEmail = authState.psychologist!.email;
      userName =
          authState.psychologist!.fullName ?? authState.psychologist!.username;
    } else {
      if (mounted) {
        _showErrorSnackBar('Error: Usuario no autenticado');
      }
      setState(() => _isSubmitting = false);
      return;
    }

    final ticket = SupportTicket(
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userType: widget.userType,
      subject: _subjectController.text.trim(),
      category: _selectedCategory,
      message: _messageController.text.trim(),
      priority: _selectedPriority,
      createdAt: DateTime.now(),
    );

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/support/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken', 
        },
        body: json.encode(ticket.toMap()),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Error al enviar ticket');
        } catch (e) {
          throw Exception(
            'Error del servidor (${response.statusCode}): ${response.body}',
          );
        }
      }
    } on SocketException {
      if (mounted) {
        _showErrorSnackBar(
          'No se pudo conectar al servidor.\n'
          'Verifica que el backend esté ejecutándose.',
        );
      }
    } on FormatException {
      if (mounted) {
        _showErrorSnackBar('Respuesta inválida del servidor.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          'Error: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                '¡Mensaje enviado!',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        content: const Text(
          'Hemos recibido tu mensaje. Te responderemos lo antes posible a tu correo electrónico.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Entendido',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Ver detalles',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error detallado'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Enviar mensaje',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 900;
          final isDesktop = width >= 900;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : width,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 24 : 32)),
                child: Form(
                  key: _formKey,
                  child: _buildResponsiveLayout(
                    isDarkMode,
                    isMobile,
                    isTablet,
                    isDesktop,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveLayout(
    bool isDarkMode,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(isDarkMode, isMobile, isTablet),
        SizedBox(height: isMobile ? 20 : (isTablet ? 28 : 32)),

        if (isDesktop || isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildCategorySection(isDarkMode, isMobile, isTablet),
              ),
              SizedBox(width: isTablet ? 20 : 32),
              Expanded(
                flex: 1,
                child: _buildPrioritySection(isDarkMode, isMobile, isTablet),
              ),
            ],
          )
        else ...[
          _buildCategorySection(isDarkMode, isMobile, isTablet),
          const SizedBox(height: 20),
          _buildPrioritySection(isDarkMode, isMobile, isTablet),
        ],

        SizedBox(height: isMobile ? 20 : (isTablet ? 28 : 32)),
        _buildSubjectField(isDarkMode, isMobile, isTablet),
        SizedBox(height: isMobile ? 20 : 24),
        _buildMessageField(isDarkMode, isMobile, isTablet),
        SizedBox(height: isMobile ? 28 : 32),
        _buildSubmitButton(isDarkMode, isMobile, isTablet, isDesktop),
      ],
    );
  }

  Widget _buildInfoCard(bool isDarkMode, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
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
            Icons.info_outline,
            color: AppConstants.primaryColor,
            size: isMobile ? 22 : 24,
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Text(
              'Completa el formulario y nos pondremos en contacto contigo pronto.',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontFamily: 'Poppins',
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(bool isDarkMode, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Categoría',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: isMobile ? 6 : 8,
              runSpacing: isMobile ? 6 : 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category['value'];
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: isMobile ? 100 : 110,
                    maxWidth: constraints.maxWidth > 400 
                        ? (constraints.maxWidth - 16) / 2 
                        : constraints.maxWidth,
                  ),
                  child: _buildCategoryChip(
                    category,
                    isSelected,
                    isDarkMode,
                    isMobile,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    Map<String, dynamic> category,
    bool isSelected,
    bool isDarkMode,
    bool isMobile,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category['value'];
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: isMobile ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : (isDarkMode ? Colors.grey[850] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'],
              size: isMobile ? 14 : 16,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
            SizedBox(width: isMobile ? 5 : 6),
            Flexible(
              child: Text(
                category['label'],
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontFamily: 'Poppins',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.white70 : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection(bool isDarkMode, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Prioridad',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Expanded(
                  child: _buildPriorityChip(
                    'low',
                    'Baja',
                    Colors.green,
                    isDarkMode,
                    isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Expanded(
                  child: _buildPriorityChip(
                    'medium',
                    'Media',
                    Colors.orange,
                    isDarkMode,
                    isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Expanded(
                  child: _buildPriorityChip(
                    'high',
                    'Alta',
                    Colors.red,
                    isDarkMode,
                    isMobile,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriorityChip(
    String value,
    String label,
    Color color,
    bool isDarkMode,
    bool isMobile,
  ) {
    final isSelected = _selectedPriority == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPriority = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : (isDarkMode ? Colors.grey[850] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontFamily: 'Poppins',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? color
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectField(bool isDarkMode, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Asunto',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _subjectController,
          decoration: InputDecoration(
            hintText: 'Describe brevemente tu consulta',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isMobile ? 13 : 14,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppConstants.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 14,
            ),
          ),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isMobile ? 13 : 14,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa un asunto';
            }
            if (value.trim().length < 5) {
              return 'El asunto debe tener al menos 5 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageField(bool isDarkMode, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Mensaje',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        TextFormField(
          controller: _messageController,
          maxLines: null,
          minLines: isMobile ? 5 : 6,
          decoration: InputDecoration(
            hintText: 'Describe tu consulta con el mayor detalle posible...',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isMobile ? 13 : 14,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppConstants.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
          ),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isMobile ? 13 : 14,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa tu mensaje';
            }
            if (value.trim().length < 20) {
              return 'El mensaje debe tener al menos 20 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    bool isDarkMode,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    double widthFactor = 1.0;
    
    if (isDesktop) {
      widthFactor = 0.5;
    } else if (isTablet) {
      widthFactor = 0.7;
    }

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: SizedBox(
          height: isMobile ? 50 : 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: isMobile ? 18 : 20,
                    width: isMobile ? 18 : 20,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Enviar mensaje',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}