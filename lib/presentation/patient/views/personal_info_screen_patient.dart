import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_event.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class PersonalInfoScreenPatient extends StatefulWidget {
  const PersonalInfoScreenPatient({super.key});

  @override
  _PersonalInfoScreenPatientState createState() => _PersonalInfoScreenPatientState();
}

class _PersonalInfoScreenPatientState extends State<PersonalInfoScreenPatient> {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _profileImageFile;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final authState = BlocProvider.of<AuthBloc>(context).state;
    if (authState.isAuthenticatedPatient && authState.patient != null) {
      _nameController.text = authState.patient!.username ?? '';
      _dobController.text = authState.patient!.dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(authState.patient!.dateOfBirth!)
          : '';
      _phoneController.text = authState.patient!.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImageFile = File(image.path);
        });
        
        await _uploadProfilePicture();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_profileImageFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imagePath = _profileImageFile!.path;
      
      context.read<ProfileBloc>().add(ProfilePictureUploadRequested(imagePath));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo foto de perfil...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar subida: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _showDatePicker() async {
    DateTime initialDate = DateTime.now();
    try {
      final authState = BlocProvider.of<AuthBloc>(context).state;
      if (authState.isAuthenticatedPatient &&
          authState.patient != null &&
          authState.patient!.dateOfBirth != null) {
        initialDate = authState.patient!.dateOfBirth!;
      }
    } catch (e) {
      // Si hay un error, usa la fecha actual
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ?? 'Perfil actualizado con éxito',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
            } else if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ?? 'Error al actualizar el perfil',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
            }
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (_isUploadingImage && mounted) {
              if (state is ProfileUpdateSuccess || state is ProfileError) {
                setState(() {
                  _isUploadingImage = false;
                  if (state is ProfileUpdateSuccess) {
                      _profileImageFile = null; 
                  }
                });
              }
            }
            if (state is ProfileUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perfil actualizado correctamente.'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is ProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.isLoading) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (!authState.isAuthenticatedPatient || authState.patient == null) {
            return const Center(
              child: Text('Error: Usuario no autenticado o datos no disponibles.'),
            );
          }

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text(
                'Información Personal',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
              ),
              backgroundColor: accentColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingImage ? null : _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                BlocBuilder<ProfileBloc, ProfileState>(
                                  builder: (context, profileState) {
                                    String? imageUrl;
                                    
                                    if (profileState is ProfileLoaded) {
                                      imageUrl = profileState.profileData.profilePictureUrl;
                                    }
                                    
                                    return CircleAvatar(
                                      radius: 50,
                                      backgroundColor: lightAccentColor,
                                      backgroundImage: _profileImageFile != null
                                          ? FileImage(_profileImageFile!) as ImageProvider
                                          : (imageUrl != null && imageUrl.isNotEmpty
                                              ? NetworkImage(imageUrl) as ImageProvider
                                              : null),
                                      child: _profileImageFile == null && (imageUrl == null || imageUrl.isEmpty)
                                          ? const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.white,
                                            )
                                          : null,
                                    );
                                  },
                                ),
                                if (_isUploadingImage)
                                  const Positioned.fill(
                                    child: Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: primaryColor,
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isUploadingImage
                                ? 'Subiendo foto...'
                                : 'Toca para cambiar foto',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).hintColor,
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
                    _buildInputFieldWithLabel(context, _nameController, 'Nombre'),
                    _buildInputFieldWithLabel(
                      context,
                      _dobController,
                      'Fecha de nacimiento',
                      onTap: _showDatePicker,
                    ),
                    _buildInputFieldWithLabel(
                      context,
                      _phoneController,
                      'Número de teléfono',
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState != null &&
                              _formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              UpdatePatientInfoRequested(
                                name: _nameController.text,
                                dob: _dobController.text,
                                phone: _phoneController.text,
                              ),
                            );
                          }
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputFieldWithLabel(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool isEditable = true,
    int maxLines = 1,
    VoidCallback? onTap,
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
              color: Theme.of(context).hintColor,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            readOnly: onTap != null || !isEditable,
            maxLines: maxLines,
            onTap: onTap,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 10.0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            validator: (value) {
              if (label.contains('Nombre') && (value == null || value.isEmpty)) {
                return 'El nombre no puede estar vacío';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}