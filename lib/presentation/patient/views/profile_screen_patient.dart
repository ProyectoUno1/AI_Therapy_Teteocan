import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/profile_list_item.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/views/subscription_screen.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_state.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/bloc/subscription_event.dart';
import 'package:ai_therapy_teteocan/data/repositories/subscription_repository.dart';
import 'package:ai_therapy_teteocan/data/repositories/patient_profile_repository.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_event.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/profile_state.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/personal_info_screen_patient.dart';
import 'package:ai_therapy_teteocan/presentation/shared/ai_usage_limit_indicator.dart';
import 'package:ai_therapy_teteocan/presentation/shared/privacy_policy_screen.dart';
import 'package:ai_therapy_teteocan/data/repositories/payment_history_repository.dart';
import 'package:ai_therapy_teteocan/presentation/payment_history/bloc/payment_history_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/payment_history/view/payment_history_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/support_screen.dart';
import 'package:ai_therapy_teteocan/presentation/theme/views/theme_settings_screen.dart';

class ProfileScreenPatient extends StatefulWidget {
  const ProfileScreenPatient({super.key});

  @override
  _ProfileScreenPatientState createState() => _ProfileScreenPatientState();
}

class _ProfileScreenPatientState extends State<ProfileScreenPatient> {
  bool _isPopupNotificationsActive = true;
  bool _isEmailNotificationsActive = true;

  final Color primaryColor = AppConstants.primaryColor;
  final Color accentColor = AppConstants.accentColor;
  final Color lightAccentColor = AppConstants.lightAccentColor;
  final Color warningColor = AppConstants.warningColor;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState.isAuthenticatedPatient && authState.patient?.uid != null) {
      context.read<AuthBloc>().add(
        AuthStartListeningToPatient(authState.patient!.uid),
      );
      context.read<ProfileBloc>().add(ProfileFetchRequested());
    }
  }

  void _onLogoutPressed() {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = ResponsiveUtils.isTablet(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final orientation = mediaQuery.orientation;
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              SubscriptionBloc(repository: SubscriptionRepositoryImpl())
                ..add(LoadSubscriptionStatus()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: _getAdaptivePadding(screenWidth, orientation, isDesktop, isTablet),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : (isTablet ? 600 : double.infinity),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProfileHeader(context, screenWidth, isTablet, screenHeight),
                      _buildSpacing(24, screenWidth, screenHeight),
                      _buildUsageSection(context, screenWidth),
                      _buildSpacing(24, screenWidth, screenHeight),
                      _buildAccountSection(context, screenWidth),
                      _buildSpacing(24, screenWidth, screenHeight),
                      _buildSettingsSection(context, screenWidth),
                      _buildSpacing(30, screenWidth, screenHeight),
                      _buildLogoutButton(context, screenWidth, screenHeight),
                      _buildSpacing(50, screenWidth, screenHeight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ PADDING ADAPTATIVO MEJORADO
  EdgeInsets _getAdaptivePadding(double screenWidth, Orientation orientation, bool isDesktop, bool isTablet) {
    if (isDesktop) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.1,
        vertical: screenWidth * 0.03,
      );
    } else if (isTablet) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.025,
      );
    } else {
      return orientation == Orientation.portrait
          ? EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.02,
            )
          : EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: screenWidth * 0.025,
            );
    }
  }

  // ✅ ESPACIADO ADAPTATIVO MEJORADO
  Widget _buildSpacing(double baseHeight, double screenWidth, double screenHeight) {
    final multiplier = screenWidth > 1200 ? 1.3 : (screenWidth > 600 ? 1.1 : 1.0);
    final heightRatio = screenHeight / 812; // Base en iPhone 13 height
    return SizedBox(height: baseHeight * multiplier * heightRatio);
  }

  // ✅ ENCABEZADO DEL PERFIL MEJORADO CON AUTO-AJUSTE DE TEXTO
  Widget _buildProfileHeader(BuildContext context, double screenWidth, bool isTablet, double screenHeight) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Cargando...';
        String userEmail = '';
        String profileImageUrl = 'https://picsum.photos/seed/768/600';

        if (authState.status == AuthStatus.authenticated && authState.patient != null) {
          userName = authState.patient!.username;
          userEmail = authState.patient!.email;
        }

        return Container(
          width: double.infinity,
          padding: isTablet 
              ? EdgeInsets.all(screenWidth * 0.04)
              : EdgeInsets.all(screenWidth * 0.045),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(_getResponsiveSize(screenWidth, 12, 16, 20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar responsivo
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  String imageUrl = profileImageUrl;
                  if (profileState is ProfileLoaded && profileState.profileData.profilePictureUrl != null) {
                    imageUrl = profileState.profileData.profilePictureUrl!;
                  }

                  return Container(
                    width: _getResponsiveSize(screenWidth, 50, 60, 70),
                    height: _getResponsiveSize(screenWidth, 50, 60, 70),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isTablet ? 20 : 16,
                    right: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre con auto-ajuste de texto
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(screenWidth, 14, 16, 18),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      // Email con auto-ajuste de texto
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(screenWidth, 12, 14, 15),
                            color: Theme.of(context).hintColor,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botón de editar responsivo
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: _getResponsiveSize(screenWidth, 16, 18, 20),
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<ProfileBloc>(),
                        child: PersonalInfoScreenPatient(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ SECCIÓN DE USO DE IA MEJORADA
  Widget _buildUsageSection(BuildContext context, double screenWidth) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        int usedMessages = 0;
        int messageLimit = 5;
        bool isPremium = false;

        if (profileState is ProfileLoaded) {
          usedMessages = profileState.profileData.usedMessages ?? 0;
          isPremium = profileState.profileData.isPremium ?? false;
          messageLimit = isPremium ? 99999 : 5;
        }

        return AiUsageLimitIndicator(
          used: usedMessages,
          limit: messageLimit,
          isPremium: isPremium,
        );
      },
    );
  }

  // ✅ SECCIÓN DE CUENTA MEJORADA
  Widget _buildAccountSection(BuildContext context, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cuenta', screenWidth),
        _buildSpacing(12, screenWidth, MediaQuery.of(context).size.height),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(_getResponsiveSize(screenWidth, 12, 16, 20)),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              ProfileListItem(
                icon: Icons.military_tech_outlined,
                text: 'Suscripción',
                secondaryText: 'Gestionar Suscripción',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
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
                icon: Icons.credit_card_outlined,
                text: 'Pagos',
                secondaryText: 'Ver historial',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => PaymentHistoryBloc(
                          PaymentHistoryRepositoryImpl(),
                        ),
                        child: const PaymentHistoryScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ SECCIÓN DE CONFIGURACIÓN MEJORADA
  Widget _buildSettingsSection(BuildContext context, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Configuración y Ayuda', screenWidth),
        _buildSpacing(12, screenWidth, MediaQuery.of(context).size.height),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(_getResponsiveSize(screenWidth, 12, 16, 20)),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Column(
            children: [
              ProfileListItem(
                icon: Icons.settings_outlined,
                text: 'Configuración',
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
              ProfileListItem(
                icon: Icons.contact_support_outlined,
                text: 'Contáctanos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupportScreen(userType: 'patient'),
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
                icon: Icons.privacy_tip_outlined,
                text: 'Políticas de Privacidad',
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
        ),
      ],
    );
  }

  // ✅ BOTÓN DE CERRAR SESIÓN MEJORADO
  Widget _buildLogoutButton(BuildContext context, double screenWidth, double screenHeight) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated && !Navigator.of(context).canPop()) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión cerrada exitosamente.'),
            ),
          );
        } else if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: _getResponsiveSize(screenWidth, 45, 50, 55),
          child: ElevatedButton(
            onPressed: state.status == AuthStatus.loading
                ? null
                : () {
                    _showLogoutConfirmationDialog(context, screenWidth, screenHeight);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_getResponsiveSize(screenWidth, 12, 16, 20)),
              ),
              elevation: 5,
            ),
            child: state.status == AuthStatus.loading
                ? SizedBox(
                    width: _getResponsiveSize(screenWidth, 20, 24, 28),
                    height: _getResponsiveSize(screenWidth, 20, 24, 28),
                    child: const CircularProgressIndicator(color: Colors.white),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'CERRAR SESIÓN',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(screenWidth, 14, 16, 18),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ✅ TÍTULO DE SECCIÓN MEJORADO
  Widget _buildSectionTitle(String title, double screenWidth) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        title,
        style: TextStyle(
          fontSize: _getResponsiveFontSize(screenWidth, 14, 16, 18),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  // ✅ DIÁLOGO DE CONFIRMACIÓN MEJORADO
  void _showLogoutConfirmationDialog(BuildContext context, double screenWidth, double screenHeight) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final isTablet = ResponsiveUtils.isTablet(context);
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getResponsiveSize(screenWidth, 12, 16, 20)),
          ),
          child: Padding(
            padding: isTablet 
                ? EdgeInsets.all(screenWidth * 0.04)
                : EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(screenWidth, 16, 18, 20),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '¿Estás seguro de que quieres cerrar tu sesión?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(screenWidth, 14, 15, 16),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(screenWidth, 14, 15, 16),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: ElevatedButton(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Sí, Cerrar Sesión',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(screenWidth, 14, 15, 16),
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context.read<AuthBloc>().add(const AuthSignOutRequested());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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

  // ✅ FUNCIONES AUXILIARES PARA TAMAÑOS ADAPTATIVOS
  double _getResponsiveSize(double screenWidth, double mobile, double tablet, double desktop) {
    if (screenWidth > 1200) return desktop;
    if (screenWidth > 600) return tablet;
    return mobile;
  }

  double _getResponsiveFontSize(double screenWidth, double mobile, double tablet, double desktop) {
    if (screenWidth > 1200) return desktop;
    if (screenWidth > 600) return tablet;
    return mobile;
  }

  double _getAvatarSize(double screenWidth) {
    return _getResponsiveSize(screenWidth, 56, 64, 70);
  }

  double _getTitleFontSize(double screenWidth) {
    return _getResponsiveFontSize(screenWidth, 16, 17, 18);
  }

  double _getSubtitleFontSize(double screenWidth) {
    return _getResponsiveFontSize(screenWidth, 13, 14, 15);
  }

  double _getIconSize(double screenWidth) {
    return _getResponsiveSize(screenWidth, 16, 17, 18);
  }

  double _getBorderRadius(double screenWidth) {
    return _getResponsiveSize(screenWidth, 14, 16, 18);
  }

  double _getButtonHeight(double screenWidth) {
    return _getResponsiveSize(screenWidth, 48, 52, 56);
  }

  double _getButtonFontSize(double screenWidth) {
    return _getResponsiveFontSize(screenWidth, 15, 16, 17);
  }
}