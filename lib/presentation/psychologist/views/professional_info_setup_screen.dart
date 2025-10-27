// lib/presentation/psychologist/views/professional_info_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/shared/custom_text_field.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_event.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart';
import 'package:ai_therapy_teteocan/data/datasources/psychologist_remote_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfessionalInfoSetupScreen extends StatefulWidget {
  final PsychologistModel? psychologist;

  const ProfessionalInfoSetupScreen({super.key, this.psychologist});

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
  final TextEditingController _priceController = TextEditingController();

  String? _selectedSpecialty;
  final List<String> _selectedSubSpecialties = [];

  final Map<String, TimeOfDay?> _startSchedule = {
    'Lunes': null,
    'Martes': null,
    'Miércoles': null,
    'Jueves': null,
    'Viernes': null,
    'Sábado': null,
    'Domingo': null,
  };

  final Map<String, TimeOfDay?> _endSchedule = {
    'Lunes': null,
    'Martes': null,
    'Miércoles': null,
    'Jueves': null,
    'Viernes': null,
    'Sábado': null,
    'Domingo': null,
  };

  // Variables de estado
  File? _profileImage;
  String? _currentProfilePictureUrl;
  bool _isUploadingImage = false;
  bool _isDataLoaded = false;

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
  void initState() {
    super.initState();
    
    print('🔄 InitState - ProfessionalInfoSetupScreen');
    
    // Cargar datos del widget si existen
    if (widget.psychologist != null) {
      print('📦 Cargando datos desde widget.psychologist');
      _fillFormWithData(widget.psychologist!);
      _isDataLoaded = true;
    }
    
    // Cargar datos desde Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !_isDataLoaded) {
      print('🔍 Cargando datos desde Firestore para UID: $uid');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PsychologistInfoBloc>().add(
          LoadPsychologistInfoEvent(uid: uid)
        );
      });
    }
  }

  void _fillFormWithData(PsychologistModel psychologist) {
    print('📝 Llenando formulario con datos del psicólogo');
    print('👤 Nombre: ${psychologist.fullName}');
    print('🎓 Título: ${psychologist.professionalTitle}');
    print('📋 Cédula: ${psychologist.professionalLicense}');
    
    setState(() {
      // Información personal
      _fullNameController.text = psychologist.fullName ?? '';
      _professionalTitleController.text = psychologist.professionalTitle ?? '';
      _licenseNumberController.text = psychologist.professionalLicense ?? '';
      _currentProfilePictureUrl = psychologist.profilePictureUrl;
      
      // Información profesional
      _yearsExperienceController.text = psychologist.yearsExperience?.toString() ?? '';
      _descriptionController.text = psychologist.description ?? '';
      _priceController.text = psychologist.price?.toString() ?? '';

      // Educación y certificaciones
      if (psychologist.education != null && psychologist.education!.isNotEmpty) {
        _educationController.text = psychologist.education!.join('\n');
      }
      if (psychologist.certifications != null && psychologist.certifications!.isNotEmpty) {
        _certificationsController.text = psychologist.certifications!.join('\n');
      }

      // Especialidad
      _selectedSpecialty = psychologist.specialty;
      if (psychologist.subSpecialties != null) {
        _selectedSubSpecialties.clear();
        _selectedSubSpecialties.addAll(psychologist.subSpecialties!);
      }

      // Horarios
      _startSchedule.clear();
      _endSchedule.clear();
      
      if (psychologist.schedule != null && psychologist.schedule is Map) {
        (psychologist.schedule as Map<String, dynamic>).forEach((day, times) {
          if (times is Map) {
            final startTime = times['startTime'];
            final endTime = times['endTime'];
            
            if (startTime != null && endTime != null) {
              try {
                final startParts = startTime.toString().split(':');
                final endParts = endTime.toString().split(':');
                
                _startSchedule[day] = TimeOfDay(
                  hour: int.parse(startParts[0]),
                  minute: int.parse(startParts[1]),
                );
                _endSchedule[day] = TimeOfDay(
                  hour: int.parse(endParts[0]),
                  minute: int.parse(endParts[1]),
                );
                
                print('📅 Horario cargado - $day: $startTime - $endTime');
              } catch (e) {
                print('⚠️ Error parseando horario de $day: $e');
              }
            }
          }
        });
      }

      _isDataLoaded = true;
    });
    
    print('✅ Formulario llenado exitosamente');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _professionalTitleController.dispose();
    _licenseNumberController.dispose();
    _yearsExperienceController.dispose();
    _descriptionController.dispose();
    _educationController.dispose();
    _certificationsController.dispose();
    _priceController.dispose();
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
        await _uploadProfilePicture(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    if (_isUploadingImage) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final remoteDataSource = PsychologistRemoteDataSource();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 16),
                Text('Subiendo imagen...'),
              ],
            ),
            duration: Duration(minutes: 2),
          ),
        );
      }
      
      final uploadedUrl = await remoteDataSource.uploadProfilePicture(
        imageFile.path,
      );
      
      setState(() {
        _currentProfilePictureUrl = uploadedUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Imagen subida exitosamente'), 
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
          _startSchedule[day] = picked;
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
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
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
                  child: _isUploadingImage
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppConstants.lightAccentColor,
                          ),
                        )
                      : (_profileImage != null || _currentProfilePictureUrl != null)
                          ? ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    )
                                  : Image.network(
                                      _currentProfilePictureUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppConstants.lightAccentColor,
                                        );
                                      },
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
              if (_currentProfilePictureUrl != null && !_isUploadingImage)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 32),

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
          'Información Profesional',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Completa tu información profesional',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 32),

        CustomTextField(
          controller: _yearsExperienceController,
          hintText: 'Años de experiencia',
          icon: Icons.work_outline,
          filled: true,
          fillColor: Colors.grey[100]!,
          borderRadius: 12,
          placeholderColor: Colors.grey,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor ingresa tus años de experiencia';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Descripción profesional (mínimo 50 caracteres)',
              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(Icons.description_outlined, color: Colors.grey),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Por favor ingresa una descripción';
              }
              if ((value?.length ?? 0) < 50) {
                return 'La descripción debe tener al menos 50 caracteres';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _educationController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Educación (separa cada título con una nueva línea)',
              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(Icons.school_outlined, color: Colors.grey),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Por favor ingresa tu educación';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _certificationsController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Certificaciones (separa cada una con una nueva línea)',
              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(
                Icons.card_membership_outlined,
                color: Colors.grey,
              ),
            ),
          ),
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

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            isExpanded: true, 
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
                  overflow: TextOverflow.ellipsis,
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

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Precio por consulta (MXN)',
              hintStyle: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(Icons.attach_money, color: Colors.grey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingrese un precio';
              }
              final n = num.tryParse(value);
              if (n == null) {
                return '"$value" no es un número válido';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 20),

        RichText(
          text: const TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 14),
            children: <TextSpan>[
              TextSpan(
                text: 'Aviso: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    'El precio se evaluará manualmente según la especialidad y la experiencia',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.lightAccentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.lightAccentColor.withOpacity(0.3),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstants.lightAccentColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Información importante',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• Las tarifas por sesión serán establecidas por el administrador si no cumple con los requisitos \n'
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
                                _startSchedule[day]?.format(context) ??
                                    'Inicio',
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
                      _startSchedule[day] != null
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _startSchedule[day] != null
                          ? AppConstants.lightAccentColor
                          : Colors.grey,
                    ),
                    onPressed: () {
                      if (_startSchedule[day] != null) {
                        setState(() {
                          _startSchedule[day] = null;
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, completa todos los campos requeridos.'),
          ),
        );
      }
    } else {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final educationList = _educationController.text
              .split('\n')
              .where((s) => s.isNotEmpty)
              .toList();
          final certificationsList = _certificationsController.text
              .split('\n')
              .where((s) => s.isNotEmpty)
              .toList();

          final double? price = _priceController.text.isNotEmpty
              ? double.tryParse(_priceController.text)
              : null;

          final Map<String, Map<String, String>> formattedSchedule = {};
          _startSchedule.forEach((day, time) {
            if (time != null && _endSchedule[day] != null) {
              formattedSchedule[day] = {
                'startTime': _formatTimeOfDay(time),
                'endTime': _formatTimeOfDay(_endSchedule[day]!),
              };
            }
          });

          print('💾 Guardando información profesional...');
          print('📸 URL de imagen: $_currentProfilePictureUrl');

          context.read<PsychologistInfoBloc>().add(
            SetupProfessionalInfoEvent(
              uid: user.uid,
              email: user.email ?? '',
              fullName: _fullNameController.text,
              professionalTitle: _professionalTitleController.text,
              licenseNumber: _licenseNumberController.text,
              yearsExperience: int.tryParse(_yearsExperienceController.text) ?? 0,
              description: _descriptionController.text,
              education: educationList,
              certifications: certificationsList,
              profilePictureUrl: _currentProfilePictureUrl,
              selectedSpecialty: _selectedSpecialty,
              selectedSubSpecialties: _selectedSubSpecialties,
              schedule: formattedSchedule,
              isAvailable: true,
              price: price,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No hay un usuario autenticado.'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.Hm();
    return format.format(dt);
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
        return _startSchedule.values.any((time) => time != null);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PsychologistInfoBloc, PsychologistInfoState>(
      listener: (context, state) {
        if (state is PsychologistInfoLoaded && !_isDataLoaded) {
          print('🔄 Datos cargados desde Bloc');
          _fillFormWithData(state.psychologist);
        } else if (state is PsychologistInfoSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Perfil profesional configurado exitosamente!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PsychologistHomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else if (state is PsychologistInfoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: ${state.message}'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
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
          title: const Text(
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
        body: BlocBuilder<PsychologistInfoBloc, PsychologistInfoState>(
          builder: (context, state) {
            if (state is PsychologistInfoLoading && !_isDataLoaded) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Form(
              key: _formKey,
              child: Column(
                children: [
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

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildStepContent(),
                    ),
                  ),

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
                          child: ElevatedButton(
                            onPressed: state is PsychologistInfoLoading 
                                ? null 
                                : _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.lightAccentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: state is PsychologistInfoLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _currentStep < 3 ? 'Siguiente' : 'Finalizar',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}