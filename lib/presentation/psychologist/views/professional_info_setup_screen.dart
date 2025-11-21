// lib/presentation/psychologist/views/professional_info_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
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

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _professionalTitleController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _yearsExperienceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _certificationsController = TextEditingController();
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

  File? _profileImage;
  String? _currentProfilePictureUrl;
  bool _isUploadingImage = false;
  bool _isDataLoaded = false;

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
    
    if (widget.psychologist != null) {
      _fillFormWithData(widget.psychologist!);
      _isDataLoaded = true;
    }
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !_isDataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PsychologistInfoBloc>().add(
          LoadPsychologistInfoEvent(uid: uid)
        );
      });
    }
  }

  void _fillFormWithData(PsychologistModel psychologist) {
    setState(() {
      _fullNameController.text = psychologist.fullName ?? '';
      _professionalTitleController.text = psychologist.professionalTitle ?? '';
      _licenseNumberController.text = psychologist.professionalLicense ?? '';
      _currentProfilePictureUrl = psychologist.profilePictureUrl;
      
      _yearsExperienceController.text = psychologist.yearsExperience?.toString() ?? '';
      _descriptionController.text = psychologist.description ?? '';
      _priceController.text = psychologist.price?.toString() ?? '';

      if (psychologist.education != null && psychologist.education!.isNotEmpty) {
        _educationController.text = psychologist.education!.join('\n');
      }
      if (psychologist.certifications != null && psychologist.certifications!.isNotEmpty) {
        _certificationsController.text = psychologist.certifications!.join('\n');
      }

      _selectedSpecialty = psychologist.specialty;
      if (psychologist.subSpecialties != null) {
        _selectedSubSpecialties.clear();
        _selectedSubSpecialties.addAll(psychologist.subSpecialties!);
      }

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
              } catch (e) {
                print('⚠️ Error parseando horario de $day: $e');
              }
            }
          }
        });
      }

      _isDataLoaded = true;
    });
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppConstants.lightAccentColor,
            ),
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
    final avatarSize = ResponsiveUtils.getAvatarRadius(context, 60);
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Información Personal',
          baseFontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(8),
        ResponsiveText(
          'Completa tu perfil profesional',
          baseFontSize: 16,
          color: Colors.grey,
        ),
        ResponsiveSpacing(32),
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
                child: Container(
                  width: avatarSize * 2,
                  height: avatarSize * 2,
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
                                      width: avatarSize * 2,
                                      height: avatarSize * 2,
                                    )
                                  : Image.network(
                                      _currentProfilePictureUrl!,
                                      fit: BoxFit.cover,
                                      width: avatarSize * 2,
                                      height: avatarSize * 2,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: avatarSize,
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
                                  size: ResponsiveUtils.getIconSize(context, 32),
                                  color: AppConstants.lightAccentColor,
                                ),
                                ResponsiveSpacing(8),
                                ResponsiveText(
                                  'Agregar foto',
                                  baseFontSize: 12,
                                  color: Colors.grey,
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
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: ResponsiveUtils.getIconSize(context, 16),
                    ),
                  ),
                ),
            ],
          ),
        ),

        ResponsiveSpacing(32),

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

        ResponsiveSpacing(16),

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

        ResponsiveSpacing(16),

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
        ResponsiveText(
          'Información Profesional',
          baseFontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(8),
        ResponsiveText(
          'Completa tu información profesional',
          baseFontSize: 16,
          color: Colors.grey,
        ),
        ResponsiveSpacing(32),

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

        ResponsiveSpacing(16),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 12),
            ),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: ResponsiveUtils.isMobileSmall(context) ? 3 : 4,
            decoration: InputDecoration(
              hintText: 'Descripción profesional (mínimo 50 caracteres)',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: ResponsiveUtils.getFontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(
                ResponsiveUtils.getHorizontalPadding(context),
              ),
              prefixIcon: Icon(
                Icons.description_outlined,
                color: Colors.grey,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
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

        ResponsiveSpacing(16),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 12),
            ),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _educationController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Educación (separa cada título con una nueva línea)',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: ResponsiveUtils.getFontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(
                ResponsiveUtils.getHorizontalPadding(context),
              ),
              prefixIcon: Icon(
                Icons.school_outlined,
                color: Colors.grey,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Por favor ingresa tu educación';
              }
              return null;
            },
          ),
        ),

        ResponsiveSpacing(16),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 12),
            ),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _certificationsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Certificaciones (separa cada una con una nueva línea)',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: ResponsiveUtils.getFontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(ResponsiveUtils.getBorderRadius(context, 12)),
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(
                ResponsiveUtils.getHorizontalPadding(context),
              ),
              prefixIcon: Icon(
                Icons.card_membership_outlined,
                color: Colors.grey,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyStep() {
    final borderRadius = ResponsiveUtils.getBorderRadius(context, 12);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Especialidades',
          baseFontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(8),
        ResponsiveText(
          'Selecciona tu especialidad principal',
          baseFontSize: 16,
          color: Colors.grey,
        ),
        ResponsiveSpacing(24),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedSpecialty,
            decoration: InputDecoration(
              hintText: 'Selecciona tu especialidad principal',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: ResponsiveUtils.getFontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getHorizontalPadding(context),
                vertical: ResponsiveUtils.getVerticalPadding(context),
              ),
              prefixIcon: Icon(
                Icons.psychology,
                color: Colors.grey,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
            ),
            items: _specialties.map((specialty) {
              return DropdownMenuItem(
                value: specialty,
                child: Text(
                  specialty,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: ResponsiveUtils.getFontSize(context, 14),
                  ),
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

        ResponsiveSpacing(24),

        if (_selectedSpecialty != null &&
            _subSpecialties.containsKey(_selectedSpecialty)) ...[
          ResponsiveText(
            'Sub-especialidades (opcional)',
            baseFontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          ResponsiveSpacing(12),
          Wrap(
            spacing: ResponsiveUtils.getHorizontalSpacing(context, 8),
            runSpacing: ResponsiveUtils.getVerticalSpacing(context, 8),
            children: _subSpecialties[_selectedSpecialty]!.map((subSpecialty) {
              final isSelected = _selectedSubSpecialties.contains(subSpecialty);
              return FilterChip(
                label: Text(
                  subSpecialty,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppConstants.lightAccentColor,
                    fontFamily: 'Poppins',
                    fontSize: ResponsiveUtils.getFontSize(context, 12),
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

        ResponsiveSpacing(24),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Precio por consulta (MXN)',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
                fontSize: ResponsiveUtils.getFontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(
                ResponsiveUtils.getHorizontalPadding(context),
              ),
              prefixIcon: Icon(
                Icons.attach_money,
                color: Colors.grey,
                size: ResponsiveUtils.getIconSize(context, 24),
              ),
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

        ResponsiveSpacing(20),

        ResponsiveText(
          'Aviso: El precio se evaluará manualmente según la especialidad y la experiencia',
          baseFontSize: 14,
          color: Colors.black,
        ),

        ResponsiveSpacing(24),

        Container(
          padding: EdgeInsets.all(ResponsiveUtils.getHorizontalPadding(context)),
          decoration: BoxDecoration(
            color: AppConstants.lightAccentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
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
                    size: ResponsiveUtils.getIconSize(context, 20),
                  ),
                  ResponsiveHorizontalSpacing(8),
                  ResponsiveText(
                    'Información importante',
                    baseFontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
              ResponsiveSpacing(8),
              ResponsiveText(
                '• Las tarifas por sesión serán establecidas por el administrador si no cumple con los requisitos \n'
                '• Las modalidades de atención (presencial/en línea) se configurarán posteriormente\n'
                '• Tu perfil será revisado antes de ser publicado para los pacientes',
                baseFontSize: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    final isMobileSmall = ResponsiveUtils.isMobileSmall(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Horarios de Disponibilidad',
          baseFontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(8),
        ResponsiveText(
          'Define tu disponibilidad semanal',
          baseFontSize: 16,
          color: Colors.grey,
        ),
        ResponsiveSpacing(24),
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
            margin: EdgeInsets.only(
              bottom: ResponsiveUtils.getVerticalSpacing(context, 8),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ResponsiveUtils.getHorizontalPadding(context),
              ),
              child: Column(
                children: [
                  if (isMobileSmall)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          day,
                          baseFontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        ResponsiveSpacing(8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeSelector(day, false),
                            ),
                            ResponsiveHorizontalSpacing(8),
                            ResponsiveText('-', baseFontSize: 16, fontWeight: FontWeight.bold),
                            ResponsiveHorizontalSpacing(8),
                            Expanded(
                              child: _buildTimeSelector(day, true),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: ResponsiveText(
                            day,
                            baseFontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildTimeSelector(day, false)),
                              ResponsiveHorizontalSpacing(8),
                              ResponsiveText('-', baseFontSize: 16, fontWeight: FontWeight.bold),
                              ResponsiveHorizontalSpacing(8),
                              Expanded(child: _buildTimeSelector(day, true)),
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
                            size: ResponsiveUtils.getIconSize(context, 24),
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
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimeSelector(String day, bool isEndTime) {
    final time = isEndTime ? _endSchedule[day] : _startSchedule[day];
    
    return GestureDetector(
      onTap: () => _selectTime(day, isEndTime),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getHorizontalSpacing(context, 12),
          vertical: ResponsiveUtils.getVerticalSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getBorderRadius(context, 8),
          ),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: ResponsiveText(
            time?.format(context) ?? (isEndTime ? 'Fin' : 'Inicio'),
            baseFontSize: 14,
          ),
        ),
      ),
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
    final horizontalPadding = ResponsiveUtils.getHorizontalPadding(context);
    final buttonHeight = ResponsiveUtils.getButtonHeight(context);
    
    return BlocListener<PsychologistInfoBloc, PsychologistInfoState>(
      listener: (context, state) {
        if (state is PsychologistInfoLoaded && !_isDataLoaded) {
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: ResponsiveUtils.getIconSize(context, 24),
                  ),
                  onPressed: _previousStep,
                )
              : null,
          title: ResponsiveText(
            'Configuración Profesional',
            baseFontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
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
                    padding: EdgeInsets.all(horizontalPadding),
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
                      padding: EdgeInsets.all(horizontalPadding),
                      child: _buildStepContent(),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(horizontalPadding),
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
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtils.getVerticalPadding(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.getBorderRadius(context, 12),
                                  ),
                                ),
                                minimumSize: Size(0, buttonHeight),
                              ),
                              child: ResponsiveText(
                                'Anterior',
                                baseFontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.lightAccentColor,
                              ),
                            ),
                          ),
                        if (_currentStep > 0) ResponsiveHorizontalSpacing(16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state is PsychologistInfoLoading 
                                ? null 
                                : _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.lightAccentColor,
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveUtils.getVerticalPadding(context),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getBorderRadius(context, 12),
                                ),
                              ),
                              minimumSize: Size(0, buttonHeight),
                            ),
                            child: state is PsychologistInfoLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : ResponsiveText(
                                    _currentStep < 3 ? 'Siguiente' : 'Finalizar',
                                    baseFontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
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