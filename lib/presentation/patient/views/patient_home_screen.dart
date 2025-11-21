// lib/presentation/patient/views/patient_home_screen.dart

import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/chat/views/chat_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_content.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/profile_screen_patient.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/psychologists_list_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_appointments_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/shared/notification_panel_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_event.dart';
import 'package:ai_therapy_teteocan/data/repositories/notification_repository.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/terms_and_conditions_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/article_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

class PatientHomeScreen extends StatefulWidget {
  final String? initialChatPsychologistId;
  final String? initialChatId;

  const PatientHomeScreen({
    super.key,
    this.initialChatPsychologistId,
    this.initialChatId,
  });

  @override
  State<PatientHomeScreen> createState() => PatientHomeScreenState();
}

class PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;
  bool _termsDialogShown = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToPsychologistsScreen() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _goToChatScreen() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _goToHomeScreen() {
    setState(() {
      _selectedIndex = 0; // El índice 0 es 'Home'
    });
  }

  List<Widget> _buildWidgetOptions(String patientId) {
    return <Widget>[
      PatientHomeContent(patientId: patientId),
      ChatListScreen(
        onGoToPsychologists: _goToPsychologistsScreen,
        initialPsychologistId: widget.initialChatPsychologistId,
        initialChatId: widget.initialChatId,
      ),
      const PsychologistsListScreen(),
      PatientAppointmentsListScreen(onGoToHome: _goToHomeScreen,),
      const ProfileScreenPatient(),
    ];
  }

  void _checkAndShowTermsDialog() {
    if (_termsDialogShown) return;

    final authState = context.read<AuthBloc>().state;
    final patient = authState.patient;

    if (patient != null && !(patient.termsAccepted ?? false)) {
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
                userRole: 'patient',
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

  @override
  void initState() {
    super.initState();
    
    if (widget.initialChatPsychologistId != null || widget.initialChatId != null) {
      _selectedIndex = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndShowTermsDialog();
  }

  @override
  Widget build(BuildContext context) {
    String userName = 'Paciente';
    final authState = context.watch<AuthBloc>().state;
    if (authState.patient != null) {
      userName = authState.patient!.username;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (authState.patient == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final widgetOptions = _buildWidgetOptions(authState.patient!.uid);

    return FutureBuilder<String?>(
      future: user?.getIdToken(),
      builder: (context, snapshot) {
        final String? userToken = snapshot.data;
        final bool isTokenLoading = snapshot.connectionState == ConnectionState.waiting;
        final bool isUserAuthenticated = user != null && userToken != null && authState.patient != null;
        
        return BlocProvider(
          create: (context) => ArticleBloc(
            articleRepository: context.read<ArticleRepository>(),
          ),
          child: ResponsiveLayoutBuilder(
            builder: (context, constraints, isCompact, isWide) {
              // ✅ DETECTAR SI USAR LAYOUT ADAPTATIVO
              final bool useDesktopLayout = ResponsiveUtils.isDesktop(context) && 
                                           !ResponsiveUtils.isLandscape(context);
              
              if (useDesktopLayout) {
                // ✅ LAYOUT DESKTOP CON NAVIGATIONRAIL
                return _buildDesktopLayout(
                  context,
                  widgetOptions,
                  userName,
                  isTokenLoading,
                  isUserAuthenticated,
                  userToken,
                  authState,
                );
              } else {
                // ✅ LAYOUT MOBILE/TABLET CON BOTTOMNAVIGATIONBAR
                return _buildMobileLayout(
                  context,
                  widgetOptions,
                  userName,
                  isTokenLoading,
                  isUserAuthenticated,
                  userToken,
                  authState,
                );
              }
            },
          ),
        );
      },
    );
  }

  // ✅ LAYOUT PARA MÓVIL Y TABLET
  Widget _buildMobileLayout(
    BuildContext context,
    List<Widget> widgetOptions,
    String userName,
    bool isTokenLoading,
    bool isUserAuthenticated,
    String? userToken,
    AuthState authState,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(
        context,
        userName,
        isTokenLoading,
        isUserAuthenticated,
        userToken,
        authState,
      ),
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ✅ LAYOUT PARA DESKTOP
  Widget _buildDesktopLayout(
    BuildContext context,
    List<Widget> widgetOptions,
    String userName,
    bool isTokenLoading,
    bool isUserAuthenticated,
    String? userToken,
    AuthState authState,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // ✅ NAVIGATIONRAIL LATERAL
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            selectedIconTheme: IconThemeData(
              color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
              size: ResponsiveUtils.getIconSize(context, 28),
            ),
            unselectedIconTheme: IconThemeData(
              color: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
              size: ResponsiveUtils.getIconSize(context, 24),
            ),
            selectedLabelTextStyle: TextStyle(
              color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: ResponsiveUtils.getFontSize(context, 13),
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
              fontWeight: FontWeight.normal,
              fontFamily: 'Poppins',
              fontSize: ResponsiveUtils.getFontSize(context, 12),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: Text('Chats'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.psychology_outlined),
                selectedIcon: Icon(Icons.psychology),
                label: Text('Psicólogos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Citas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
              ),
            ],
          ),
          
          const VerticalDivider(thickness: 1, width: 1),
          
          // ✅ CONTENIDO PRINCIPAL
          Expanded(
            child: Column(
              children: [
                _buildAppBar(
                  context,
                  userName,
                  isTokenLoading,
                  isUserAuthenticated,
                  userToken,
                  authState,
                ),
                Expanded(
                  child: widgetOptions[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ APPBAR RESPONSIVO
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String userName,
    bool isTokenLoading,
    bool isUserAuthenticated,
    String? userToken,
    AuthState authState,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false, // ✅ QUITAR BOTÓN DE BACK EN DESKTOP
      title: ResponsiveText(
        'Buen día, $userName 👋',
        baseFontSize: ResponsiveUtils.isDesktop(context) ? 20 : 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.headlineMedium?.color,
      ),
      actions: [
        _buildNotificationButton(
          context,
          isTokenLoading,
          isUserAuthenticated,
          userToken,
          authState,
        ),
        SizedBox(width: ResponsiveUtils.getHorizontalSpacing(context, 8)),
      ],
    );
  }

  // ✅ BOTÓN DE NOTIFICACIONES
  Widget _buildNotificationButton(
    BuildContext context,
    bool isTokenLoading,
    bool isUserAuthenticated,
    String? userToken,
    AuthState authState,
  ) {
    if (isTokenLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getHorizontalSpacing(context, 12),
        ),
        child: Center(
          child: SizedBox(
            width: ResponsiveUtils.getIconSize(context, 20),
            height: ResponsiveUtils.getIconSize(context, 20),
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    if (!isUserAuthenticated) {
      return IconButton(
        icon: Icon(
          _notificationsEnabled
              ? Icons.notifications_none
              : Icons.notifications_off,
          color: Theme.of(context).iconTheme.color,
          size: ResponsiveUtils.getIconSize(context, 24),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no autenticado')),
          );
        },
      );
    }

    return BlocProvider(
      create: (context) => NotificationBloc(
        notificationRepository: NotificationRepository(),
      )..add(
          LoadNotifications(
            userId: authState.patient!.uid,
            userToken: userToken!,
            userType: 'patient',
          ),
        ),
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          int unreadCount = 0;
          if (state is NotificationLoaded) {
            unreadCount = state.notifications.where((n) => !n.isRead).length;
          }
          
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _notificationsEnabled
                      ? Icons.notifications_none
                      : Icons.notifications_off,
                  color: Theme.of(context).iconTheme.color,
                  size: ResponsiveUtils.getIconSize(context, 24),
                ),
                onPressed: () {
                  final notificationBloc = BlocProvider.of<NotificationBloc>(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: notificationBloc,
                        child: NotificationsPanelScreen(
                          onNavigateToChat: _goToChatScreen,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: ResponsiveUtils.getHorizontalSpacing(context, 8),
                  top: ResponsiveUtils.getVerticalSpacing(context, 8),
                  child: Container(
                    padding: EdgeInsets.all(
                      ResponsiveUtils.getHorizontalSpacing(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B716F),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getBorderRadius(context, 10),
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: ResponsiveUtils.getIconSize(context, 18),
                      minHeight: ResponsiveUtils.getIconSize(context, 18),
                    ),
                    child: Center(
                      child: ResponsiveText(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        baseFontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ✅ BOTTOM NAVIGATION BAR RESPONSIVO
  Widget _buildBottomNavigationBar(BuildContext context) {
    final isCompact = ResponsiveUtils.shouldShowCompactLayout(context);
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
        fontSize: ResponsiveUtils.getFontSize(context, isCompact ? 11 : 12),
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontFamily: 'Poppins',
        fontSize: ResponsiveUtils.getFontSize(context, isCompact ? 10 : 11),
      ),
      selectedFontSize: ResponsiveUtils.getFontSize(context, isCompact ? 11 : 12),
      unselectedFontSize: ResponsiveUtils.getFontSize(context, isCompact ? 10 : 11),
      iconSize: ResponsiveUtils.getIconSize(context, isCompact ? 22 : 24),
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology_outlined),
          activeIcon: Icon(Icons.psychology),
          label: 'Psicólogos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Citas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}