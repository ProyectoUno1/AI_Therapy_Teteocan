// lib/presentation/psychologist/views/psychologist_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/profile_screen_psychologist.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_content.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_chat_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_management_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/appointments_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/theme/views/theme_settings_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/chat_list_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_management_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/notification_panel_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/professional_info_setup_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/terms_and_conditions_screen.dart';

// HELPER FUNCTION PARA LIMITAR EL TEXT SCALE FACTOR
double _getConstrainedTextScaleFactor(BuildContext context, {double maxScale = 1.3}) {
  final textScaleFactor = MediaQuery.textScaleFactorOf(context);
  return textScaleFactor.clamp(1.0, maxScale);
}

// FUNCIÓN PARA OBTENER TAMAÑO DE FUENTE RESPONSIVO
double _getResponsiveFontSize(BuildContext context, double baseSize) {
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  final textScaleFactor = _getConstrainedTextScaleFactor(context);
  
  // Ajustar por orientación y tamaño de pantalla
  double scale = isLandscape ? (width / 800) : (width / 375);
  
  // Limitar el escalado para texto grande
  scale = scale.clamp(0.85, 1.2);
  
  // Reducir más en landscape con texto grande
  if (isLandscape && textScaleFactor > 1.2) {
    scale *= 0.85;
  }
  
  return (baseSize * scale).clamp(baseSize * 0.75, baseSize * 1.15);
}

class PsychologistHomeScreen extends StatefulWidget {
  final int? initialTabIndex;
  final bool showProfessionalSetupDialog;

  const PsychologistHomeScreen({
    super.key,
    this.initialTabIndex,
    this.showProfessionalSetupDialog = false,
  });

  @override
  _PsychologistHomeScreenState createState() => _PsychologistHomeScreenState();
}

class _PsychologistHomeScreenState extends State<PsychologistHomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _notificationsLoaded = false;
  bool _dialogShown = false;
  bool _termsDialogShown = false;

  void _navigateToChatTab() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  List<Widget> _getWidgetOptions(String psychologistId) {
    return <Widget>[
      const PsychologistHomeContent(),
      BlocProvider<ChatListBloc>(
        create: (context) => ChatListBloc(),
        child: const PsychologistChatListScreen(),
      ),
      BlocProvider<AppointmentBloc>(
        create: (context) => AppointmentBloc(),
        child: AppointmentsListScreen(psychologistId: psychologistId),
      ),
      BlocProvider<PatientManagementBloc>(
        create: (context) => PatientManagementBloc(),
        child: const PatientManagementScreen(),
      ),
      const ProfileScreenPsychologist(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _loadNotifications() async {
    if (_notificationsLoaded) return;
    
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      
      if (!mounted) {
        return; 
      }

      if (token != null) {
        context.read<NotificationBloc>().add(
          LoadNotifications(
            userId: user.uid,
            userToken: token,
            userType: 'psychologist',
          ),
        );
        _notificationsLoaded = true;
      }
    }
  }

  void _checkAndShowTermsDialog() {
    if (_termsDialogShown) return;

    final authState = context.read<AuthBloc>().state;
    final psychologist = authState.psychologist;

    if (psychologist != null && !(psychologist.termsAccepted ?? false)) {
      _termsDialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false, 
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: TermsAndConditionsScreen(
                userRole: 'psychologist',
              ),
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      });
    }
  }

  void _showProfessionalSetupDialog() {
    if (_dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: _getConstrainedTextScaleFactor(context),
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(_getResponsiveFontSize(context, 16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(_getResponsiveFontSize(context, 8)),
                          decoration: BoxDecoration(
                            color: const Color(0xFF82c4c3).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.workspace_premium,
                            color: const Color(0xFF82c4c3),
                            size: _getResponsiveFontSize(context, 30),
                          ),
                        ),
                        SizedBox(width: _getResponsiveFontSize(context, 12)),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '¡Bienvenido!',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: _getResponsiveFontSize(context, 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _getResponsiveFontSize(context, 16)),
                    Flexible(
                      child: Text(
                        'Para comenzar a atender pacientes, necesitas completar tu perfil profesional.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: _getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveFontSize(context, 16)),
                    Container(
                      padding: EdgeInsets.all(_getResponsiveFontSize(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDialogItem(context, Icons.school, 'Educación y certificaciones'),
                          SizedBox(height: _getResponsiveFontSize(context, 8)),
                          _buildDialogItem(context, Icons.category, 'Especialidades'),
                          SizedBox(height: _getResponsiveFontSize(context, 8)),
                          _buildDialogItem(context, Icons.access_time, 'Horarios de atención'),
                          SizedBox(height: _getResponsiveFontSize(context, 8)),
                          _buildDialogItem(context, Icons.attach_money, 'Tarifa de consulta'),
                        ],
                      ),
                    ),
                    SizedBox(height: _getResponsiveFontSize(context, 16)),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Más tarde',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                  fontSize: _getResponsiveFontSize(context, 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _getResponsiveFontSize(context, 8)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ProfessionalInfoSetupScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF82c4c3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: _getResponsiveFontSize(context, 24),
                                vertical: _getResponsiveFontSize(context, 12),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Completar ahora',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: _getResponsiveFontSize(context, 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: _getResponsiveFontSize(context, 18),
          color: const Color(0xFF82c4c3),
        ),
        SizedBox(width: _getResponsiveFontSize(context, 8)),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 13),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _notificationsLoaded = false;
  
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
    }
    if (widget.showProfessionalSetupDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfessionalSetupDialog();
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotifications();
    _checkAndShowTermsDialog();
  }

  @override
  Widget build(BuildContext context) {
    String userName = 'Psicólogo';
    final authState = context.watch<AuthBloc>().state;

    if (authState.isAuthenticatedPsychologist) {
      userName = authState.psychologist!.username;
    }

    final psychologistId = authState.psychologist?.username ?? '';
    final widgetOptions = _getWidgetOptions(psychologistId);
    
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: _getConstrainedTextScaleFactor(context),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: Theme.of(context).appBarTheme.elevation ?? 0,
          centerTitle: true,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Hola, $userName',
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                      fontSize: _getResponsiveFontSize(context, 18),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: _getResponsiveFontSize(context, 8)),
                const Text('👋', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                int unreadCount = 0;
                if (state is NotificationLoaded) {
                  unreadCount = state.notifications.where((n) => !n.isRead).length;
                }
                
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none,
                        color: Theme.of(context).appBarTheme.iconTheme?.color,
                        size: _getResponsiveFontSize(context, 24),
                      ),
                      onPressed: () async {
                        final user = _auth.currentUser;
                        if (user != null) {
                          final token = await user.getIdToken();
                          if (token != null) {
                            context.read<NotificationBloc>().add(
                              LoadNotifications(
                                userId: user.uid,
                                userToken: token,
                                userType: 'psychologist',
                              ),
                            );
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsPanelScreen(),
                              ),
                            ).then((_) {
                              context.read<NotificationBloc>().add(
                                LoadNotifications(
                                  userId: user.uid,
                                  userToken: token,
                                  userType: 'psychologist',
                                ),
                              );
                            });
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuario no autenticado')),
                          );
                        }
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B716F),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: _getResponsiveFontSize(context, 12),
                            minHeight: _getResponsiveFontSize(context, 12),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _getResponsiveFontSize(context, 8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(width: _getResponsiveFontSize(context, 10)),
          ],
        ),
        body: widgetOptions[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
            unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: _getResponsiveFontSize(context, 12),
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontFamily: 'Poppins',
              fontSize: _getResponsiveFontSize(context, 12),
            ),
            iconSize: _getResponsiveFontSize(context, 24),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Citas'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}