// lib/presentation/psychologist/views/professional_info_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/shared/custom_text_field.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';

class ProfessionalInfoSetupScreen extends StatefulWidget {
  const ProfessionalInfoSetupScreen({super.key});

  @override
  State<ProfessionalInfoSetupScreen> createState() =>
      _ProfessionalInfoSetupScreenState();
}

class _ProfessionalInfoSetupScreenState
    extends State<ProfessionalInfoSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controladores de campos
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _professionalTitleController =
      TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _yearsExperienceController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _certificationsController =
      TextEditingController();

  // Variables de estado
  File? _profileImage;
  String? _selectedSpecialty;
  Set<String> _selectedSubSpecialties = {};
  Map<String, TimeOfDay?> _schedule = {
    'Lunes': null,
    'Martes': null,
    'Miércoles': null,
    'Jueves': null,
    'Viernes': null,
    'Sábado': null,
    'Domingo': null,
  };
  Map<String, TimeOfDay?> _endSchedule = {
    'Lunes': null,
    'Martes': null,
    'Miércoles': null,
    'Jueves': null,
    'Viernes': null,
    'Sábado': null,
    'Domingo': null,
  };

  // Variables removidas: modalidades y tarifas las maneja el admin
  // bool _isAvailableOnline = true;
  // bool _isAvailableInPerson = false;

  // Listas de opciones
  final List<String> _specialties = [
    'Psicología Clínica',
    'Psicología Cognitivo-Conductual',
    'Psicoterapia Humanista',
    'Terapia de Pareja',
    'Terapia Familiar',
    'Psicología Infantil y Adolescente',
    'Neuropsicología',
    'Psicología de la Salud',
    'Adicciones y Dependencias',
    'Trastornos de la Alimentación',
    'Trauma y TEPT',
    'Ansiedad y Depresión',
    'Trastornos del Estado de Ánimo',
  ];

  final Map<String, List<String>> _subSpecialties = {
    'Psicología Clínica': [
      'Evaluación psicológica',
      'Psicodiagnóstico',
      'Intervención en crisis',
    ],
    'Ansiedad y Depresión': [
      'Trastorno de ansiedad generalizada',
      'Depresión mayor',
      'Trastorno bipolar',
      'Ataques de pánico',
    ],
    'Terapia de Pareja': [
      'Conflictos matrimoniales',
      'Comunicación de pareja',
      'Infidelidad',
      'Divorcio',
    ],
    'Psicología Infantil y Adolescente': [
      'TDAH',
      'Autismo',
      'Problemas de conducta',
      'Bullying',
    ],
    'Adicciones y Dependencias': [
      'Alcoholismo',
      'Drogadicción',
      'Ludopatía',
      'Adicciones comportamentales',
    ],
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _professionalTitleController.dispose();
    _licenseNumberController.dispose();
    _yearsExperienceController.dispose();
    _descriptionController.dispose();
    _educationController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _selectTime(String day, bool isEndTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppConstants.lightAccentColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isEndTime) {
          _endSchedule[day] = picked;
        } else {
          _schedule[day] = picked;
        }
      });
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildProfessionalInfoStep();
      case 2:
        return _buildSpecialtyStep();
      case 3:
        return _buildScheduleStep();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Personal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Completa tu perfil profesional',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 32),

        // Foto de perfil
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.lightAccentColor.withOpacity(0.1),
                border: Border.all(
                  color: AppConstants.lightAccentColor,
                  width: 2,
                ),
              ),
              child: _profileImage != null
                  ? ClipOval(
                      child: Image.file(
                        _profileImage!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 32,
                          color: AppConstants.lightAccentColor,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Agregar foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Campos de información personal
        CustomTextField(
          controller: _fullNameController,
          hintText: 'Nombre completo',
          icon: Icons.person_outline,
          filled: true,
          fillColor: Colors.grey[100]!,
          borderRadius: 12,
          placeholderColor: Colors.grey,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor ingresa tu nombre completo';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        CustomTextField(
          controller: _professionalTitleController,
          hintText: 'Título profesional (Dr., Dra., Lic., etc.)',
          icon: Icons.school_outlined,
          filled: true,
          fillColor: Colors.grey[100]!,
          borderRadius: 12,
          placeholderColor: Colors.grey,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor ingresa tu título profesional';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        CustomTextField(
          controller: _licenseNumberController,
          hintText: 'Número de cédula profesional',
          icon: Icons.badge_outlined,
          filled: true,
          fillColor: Colors.grey[100]!,
          borderRadius: 12,
          placeholderColor: Colors.grey,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor ingresa tu número de cédula';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Experiencia Profesional',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cuéntanos sobre tu experiencia',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 32),

        // Campos de información personal
        CustomTextField(
          controller: _yearsExperienceController,
          hintText: 'Años de experiencia',
          icon: Icons.work_outline,
          keyboardType: TextInputType.number,
          filled: true,
          fillColor: Colors.grey[100]!,
          borderRadius: 12,
          placeholderColor: Colors.grey,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor ingresa tus años de experiencia';
            }
            final years = int.tryParse(value!);
            if (years == null || years < 0) {
              return 'Por favor ingresa un número válido';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Descripción profesional
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  'Descripción profesional...\n\nEjemplo: "Especialista en terapia cognitivo-conductual con más de 10 años de experiencia. Ayudo a pacientes con ansiedad, depresión y trastornos del estado de ánimo."',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: const TextStyle(fontFamily: 'Poppins'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Por favor agrega una descripción profesional';
              }
              if (value!.length < 50) {
                return 'La descripción debe tener al menos 50 caracteres';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        CustomTextField(
          controller: _educationController,
          hintText: 'Formación académica (Universidad, posgrados)',
          icon: Icons.school,
          filled: true,
          fillColor: Colors.grey[100]!,
          borderRadius: 12,
          placeholderColor: Colors.grey,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor ingresa tu formación académica';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        CustomTextField(
          controller: _certificationsController,
          hintText: 'Certificaciones adicionales (opcional)',
          icon: Icons.verified_outlined,
          filled: true,
          fillColor: Colors.grey[100]!,
          borderRadius: 12,
          placeholderColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildSpecialtyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especialidades',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecciona tu especialidad principal',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 24),

        // Especialidad principal
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedSpecialty,
            decoration: const InputDecoration(
              hintText: 'Selecciona tu especialidad principal',
              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(Icons.psychology, color: Colors.grey),
            ),
            items: _specialties.map((specialty) {
              return DropdownMenuItem(
                value: specialty,
                child: Text(
                  specialty,
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpecialty = value;
                _selectedSubSpecialties.clear();
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor selecciona una especialidad';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 24),

        // Sub-especialidades
        if (_selectedSpecialty != null &&
            _subSpecialties.containsKey(_selectedSpecialty)) ...[
          const Text(
            'Sub-especialidades (opcional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subSpecialties[_selectedSpecialty]!.map((subSpecialty) {
              final isSelected = _selectedSubSpecialties.contains(subSpecialty);
              return FilterChip(
                label: Text(
                  subSpecialty,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppConstants.lightAccentColor,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppConstants.lightAccentColor,
                backgroundColor: AppConstants.lightAccentColor.withOpacity(0.1),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSubSpecialties.add(subSpecialty);
                    } else {
                      _selectedSubSpecialties.remove(subSpecialty);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 24),

        // Certificaciones adicionales
        const Text(
          'Certificaciones adicionales (opcional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _certificationsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Ej: Certificación en Terapia Familiar, Diplomado en Neuropsicología...',
            hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(16),
          ),
          style: const TextStyle(fontFamily: 'Poppins'),
        ),

        const SizedBox(height: 24),

        // Nota informativa sobre tarifas y modalidades
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.lightAccentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.lightAccentColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstants.lightAccentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Información importante',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '• Las tarifas por sesión serán establecidas por el administrador\n'
                '• Las modalidades de atención (presencial/en línea) se configurarán posteriormente\n'
                '• Tu perfil será revisado antes de ser publicado para los pacientes',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horarios de Disponibilidad',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Define tu disponibilidad semanal',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 24),

        ...[
          'Lunes',
          'Martes',
          'Miércoles',
          'Jueves',
          'Viernes',
          'Sábado',
          'Domingo',
        ].map((day) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Hora inicio
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(day, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _schedule[day]?.format(context) ?? 'Inicio',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '-',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Hora fin
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(day, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _endSchedule[day]?.format(context) ?? 'Fin',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _schedule[day] != null
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _schedule[day] != null
                          ? AppConstants.lightAccentColor
                          : Colors.grey,
                    ),
                    onPressed: () {
                      if (_schedule[day] != null) {
                        setState(() {
                          _schedule[day] = null;
                          _endSchedule[day] = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _fullNameController.text.isNotEmpty &&
            _professionalTitleController.text.isNotEmpty &&
            _licenseNumberController.text.isNotEmpty;
      case 1:
        return _yearsExperienceController.text.isNotEmpty &&
            _descriptionController.text.length >= 50 &&
            _educationController.text.isNotEmpty;
      case 2:
        return _selectedSpecialty != null;
      case 3:
        return _schedule.values.any((time) => time != null);
      default:
        return false;
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Aquí se enviaría la información al backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Perfil profesional configurado exitosamente! Las tarifas serán establecidas por el administrador.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Navegar a la pantalla de login para que el psicólogo pueda iniciar sesión
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Configuración Profesional',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Indicador de progreso
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppConstants.lightAccentColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Contenido del paso actual
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(),
              ),
            ),

            // Botones de navegación
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppConstants.lightAccentColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Anterior',
                          style: TextStyle(
                            color: AppConstants.lightAccentColor,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.lightAccentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep < 3 ? 'Continuar' : 'Finalizar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
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
}
