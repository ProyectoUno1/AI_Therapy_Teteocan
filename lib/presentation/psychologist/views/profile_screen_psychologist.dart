// lib/presentation/psychologist/views/profile_screen_psychologist.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/profile_list_item.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/professional_info_setup_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/privacy_policy_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_reviews_screen_psychologist.dart';
import 'package:ai_therapy_teteocan/presentation/theme/views/theme_settings_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/support_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/bank_info_screen.dart';

class ProfileScreenPsychologist extends StatefulWidget {
  const ProfileScreenPsychologist({super.key});
  
  @override
  _ProfileScreenPsychologistState createState() =>
      _ProfileScreenPsychologistState();
}

class _ProfileScreenPsychologistState extends State<ProfileScreenPsychologist> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getContentMargin(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveSpacing(30),
          
          // Header con información del psicólogo
          _buildProfileHeader(),
          
          ResponsiveSpacing(24),
          
          // Sección Perfil Profesional
          _buildSection(
            title: 'Perfil Profesional',
            children: [
              ProfileListItem(
                icon: Icons.work_outline,
                text: 'Información profesional',
                secondaryText: 'Editar perfil',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ProfessionalInfoSetupScreen(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              ProfileListItem(
                icon: Icons.star_outline,
                text: 'Reseñas',
                secondaryText: 'Ver calificaciones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PsychologistReviewsScreenPsychologist(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          ResponsiveSpacing(24),
          
          // Sección Cuenta
          _buildSection(
            title: 'Cuenta',
            children: [
              ProfileListItem(
                icon: Icons.account_balance_wallet_outlined,
                text: 'Información de pagos',
                secondaryText: 'Gestionar cobros',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BankInfoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          ResponsiveSpacing(24),
          
          // Sección Configuración
          _buildSection(
            title: 'Configuración',
            children: [
              ProfileListItem(
                icon: Icons.palette_outlined,
                text: 'Apariencia',
                secondaryText: 'Tema y colores',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSettingsScreen(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              ProfileListItem(
                icon: Icons.help_outline,
                text: 'Soporte',
                secondaryText: 'Ayuda y contacto',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SupportScreen(userType: 'psychologist'),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              ProfileListItem(
                icon: Icons.policy_outlined,
                text: 'Política de privacidad',
                secondaryText: 'Términos y condiciones',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          ResponsiveSpacing(32),
          
          // Botón de cerrar sesión mejorado
          _buildLogoutButton(),
          
          ResponsiveSpacing(50),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Cargando...';
        String userEmail = '';
        String professionalTitle = '';
        String? profileImageUrl;

        if (authState.status == AuthStatus.authenticated &&
            authState.psychologist != null) {
          userName = authState.psychologist!.username;
          userEmail = authState.psychologist!.email;
          professionalTitle =
              authState.psychologist!.professionalTitle ?? 'Psicólogo/a';
          profileImageUrl = authState.psychologist!.profilePictureUrl;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonalInfoScreenPsychologist(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 12),
            ),
            child: Container(
              padding: ResponsiveUtils.getCardPadding(context),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 12),
                ),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveUtils.getIconSize(context, 56),
                    height: ResponsiveUtils.getIconSize(context, 56),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: profileImageUrl != null
                        ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: ResponsiveUtils.getIconSize(context, 30),
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: ResponsiveUtils.getIconSize(context, 30),
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                  ),
                  ResponsiveHorizontalSpacing(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          userName,
                          baseFontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ResponsiveSpacing(2),
                        ResponsiveText(
                          professionalTitle,
                          baseFontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ResponsiveSpacing(2),
                        ResponsiveText(
                          userEmail,
                          baseFontSize: 12,
                          color: Theme.of(context).hintColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: ResponsiveUtils.getIconSize(context, 16),
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getHorizontalPadding(context) / 2,
          ),
          child: ResponsiveText(
            title,
            baseFontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        ResponsiveSpacing(12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 16),
            ),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated &&
            !Navigator.of(context).canPop()) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: ResponsiveUtils.getIconSize(context, 20),
                  ),
                  ResponsiveHorizontalSpacing(8),
                  const Expanded(
                    child: Text('Sesión cerrada exitosamente.'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state.status == AuthStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.white,
                    size: ResponsiveUtils.getIconSize(context, 20),
                  ),
                  ResponsiveHorizontalSpacing(8),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              backgroundColor: AppConstants.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: ResponsiveUtils.getButtonHeight(context),
          child: ElevatedButton(
            onPressed: state.status == AuthStatus.loading
                ? null
                : () {
                    _showLogoutConfirmationDialog(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getBorderRadius(context, 12),
                ),
              ),
              elevation: 0,
            ),
            child: state.status == AuthStatus.loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.red.shade700,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        size: ResponsiveUtils.getIconSize(context, 18),
                        color: Colors.red.shade700,
                      ),
                      ResponsiveHorizontalSpacing(8),
                      ResponsiveText(
                        'Cerrar Sesión',
                        baseFontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final dialogWidth = ResponsiveUtils.getDialogWidth(context);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 20),
            ),
          ),
          child: Container(
            width: dialogWidth,
            padding: ResponsiveUtils.getCardPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getIconSize(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: ResponsiveUtils.getIconSize(context, 32),
                  ),
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  'Cerrar Sesión',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(8),
                ResponsiveText(
                  '¿Estás seguro de que deseas cerrar sesión?',
                  baseFontSize: 14,
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: ResponsiveUtils.getButtonHeight(context),
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getBorderRadius(context, 10),
                              ),
                            ),
                          ),
                          child: ResponsiveText(
                            'Cancelar',
                            baseFontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    ResponsiveHorizontalSpacing(12),
                    Expanded(
                      child: SizedBox(
                        height: ResponsiveUtils.getButtonHeight(context),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            context.read<AuthBloc>().add(
                              const AuthSignOutRequested(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getBorderRadius(context, 10),
                              ),
                            ),
                          ),
                          child: ResponsiveText(
                            'Cerrar Sesión',
                            baseFontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
// Añadir esta clase al final de profile_screen_psychologist.dart

class PersonalInfoScreenPsychologist extends StatelessWidget {
  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;

  const PersonalInfoScreenPsychologist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          'Información Personal',
          baseFontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: ResponsiveUtils.getIconSize(context, 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String fullName = 'Cargando...';
          String email = '';
          String phoneNumber = '';
          String dateOfBirth = '00/00/0000';
          String? profileImageUrl;

          if (authState.status == AuthStatus.authenticated &&
              authState.psychologist != null) {
            final psychologist = authState.psychologist!;
            
            fullName = psychologist.fullName ?? psychologist.username;
            email = psychologist.email;
            phoneNumber = psychologist.phoneNumber ?? 'No registrado';
            profileImageUrl = psychologist.profilePictureUrl;

            if (psychologist.dateOfBirth != null) {
              try {
                final date = psychologist.dateOfBirth is Timestamp
                    ? (psychologist.dateOfBirth as Timestamp).toDate()
                    : DateTime.parse(psychologist.dateOfBirth.toString());
                dateOfBirth = DateFormat('dd/MM/yyyy').format(date);
              } catch (e) {
                dateOfBirth = 'No registrado';
              }
            }
          }

          return SingleChildScrollView(
            padding: ResponsiveUtils.getContentMargin(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveSpacing(24),
                
                // Profile image section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: ResponsiveUtils.getIconSize(context, 100),
                        height: ResponsiveUtils.getIconSize(context, 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lightAccentColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  profileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: ResponsiveUtils.getIconSize(context, 60),
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: ResponsiveUtils.getIconSize(context, 60),
                                color: Colors.white,
                              ),
                      ),
                      ResponsiveSpacing(10),
                      ResponsiveText(
                        'Foto de perfil',
                        baseFontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                
                ResponsiveSpacing(30),
                
                ResponsiveText(
                  'INFORMACIÓN PERSONAL',
                  baseFontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                
                ResponsiveSpacing(10),
                
                _buildInfoField(
                  context,
                  'Nombre completo',
                  fullName,
                  isEditable: false,
                ),
                _buildInfoField(
                  context,
                  'Correo electrónico',
                  email,
                  isEditable: false,
                ),
                _buildInfoField(
                  context,
                  'Número de teléfono',
                  phoneNumber,
                  isEditable: true,
                ),
                _buildInfoField(
                  context,
                  'Fecha de nacimiento',
                  dateOfBirth,
                  isEditable: false,
                ),
                
                ResponsiveSpacing(40),
                
                Center(
                  child: SizedBox(
                    width: ResponsiveUtils.isMobile(context) 
                        ? double.infinity 
                        : 300,
                    height: ResponsiveUtils.getButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.white,
                                  size: ResponsiveUtils.getIconSize(context, 20),
                                ),
                                ResponsiveHorizontalSpacing(8),
                                const Expanded(
                                  child: Text('Funcionalidad en desarrollo'),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getBorderRadius(context, 8),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getHorizontalSpacing(context, 40),
                          vertical: ResponsiveUtils.getVerticalSpacing(context, 15),
                        ),
                      ),
                      child: ResponsiveText(
                        'Guardar Cambios',
                        baseFontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                ResponsiveSpacing(24),
              ],
            ),
          );
        },
      ),
      
    );
  }

  Widget _buildInfoField(
    BuildContext context,
    String label,
    String value, {
    bool isEditable = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getVerticalSpacing(context, 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            label,
            baseFontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          ResponsiveSpacing(4),
          TextField(
            controller: TextEditingController(text: value),
            readOnly: !isEditable,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, 16),
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.getVerticalSpacing(context, 8),
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

 

  void _showHelpDialog(BuildContext context, String section, String message) {
    final dialogWidth = ResponsiveUtils.getDialogWidth(context);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 15),
            ),
          ),
          child: Container(
            width: dialogWidth,
            padding: ResponsiveUtils.getCardPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getIconSize(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: accentColor,
                    size: ResponsiveUtils.getIconSize(context, 32),
                  ),
                ),
                ResponsiveSpacing(16),
                ResponsiveText(
                  'Duda Sección $section',
                  baseFontSize: 18,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(12),
                ResponsiveText(
                  message,
                  baseFontSize: 14,
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(24),
                SizedBox(
                  width: double.infinity,
                  height: ResponsiveUtils.getButtonHeight(context),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getBorderRadius(context, 10),
                        ),
                      ),
                    ),
                    child: ResponsiveText(
                      'Entendido',
                      baseFontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}