///lib/main.dart

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/core/services/theme_service.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/psychologist_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/repositories/auth_repository_impl.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/data/repositories/psychologist_repository_impl.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/register_user_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/sign_in_usecase.dart';
import 'package:ai_therapy_teteocan/core/services/ai_chat_api_service.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

// Importaciones de las vistas y Blocs/Cubits
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_wrapper.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/appointment_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/admin/views/psychologists_list_page.dart';
import 'package:ai_therapy_teteocan/presentation/admin/bloc/psychologist_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/psychologist_repository.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_event.dart';
import 'package:ai_therapy_teteocan/presentation/shared/bloc/notification_state.dart';
import 'package:ai_therapy_teteocan/data/repositories/notification_repository.dart';
import 'package:ai_therapy_teteocan/data/repositories/article_repository.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';
import 'package:ai_therapy_teteocan/core/constants/api_constants.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';
import 'package:ai_therapy_teteocan/core/services/notification_service.dart';
import 'package:ai_therapy_teteocan/data/models/emotion_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/emotion/emotion_bloc.dart';
import 'package:ai_therapy_teteocan/data/datasources/emotion_data_source.dart';
import 'package:ai_therapy_teteocan/data/repositories/emotion_repository.dart';

import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en background: ${message.messageId}');
}

/// Punto de entrada principal de la aplicación.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- Inicialización de la base de datos de zonas horarias ---
  tzdata.initializeTimeZones();
  Stripe.publishableKey =
      'pk_test_51RvpC82Szsvtfc49A47f7EAMS4lyoNX4FjXxYL0JnwNS0jMR2jARHLsvR5ZMnHXSsYJNjw2EhNOVv4PiP785jHRJ00fGel1PLI';

  // --- NUEVA CONFIGURACIÓN: Inicializar NotificationService ---
  await NotificationService.initialize();

  // Configurar manejador de navegación desde notificaciones
  NotificationService.onNotificationTap = (data) {
    _handleNotificationNavigation(data);
  };

  // --- Inicialización de Data Sources y Repositorios de Autenticación ---
  final AuthRemoteDataSourceImpl authRemoteDataSource =
      AuthRemoteDataSourceImpl(firebaseAuth: FirebaseAuth.instance);
  final UserRemoteDataSourceImpl userRemoteDataSource =
      UserRemoteDataSourceImpl(FirebaseFirestore.instance);

  final AuthRepository authRepository = AuthRepositoryImpl(
    authRemoteDataSource: authRemoteDataSource,
    userRemoteDataSource: userRemoteDataSource,
  );

  final SignInUseCase signInUseCase = SignInUseCase(authRepository);
  final RegisterUserUseCase registerUserUseCase = RegisterUserUseCase(
    authRepository,
  );
  final ChatRepository chatRepository = ChatRepository();
  final ThemeService themeService = ThemeService();
  final psychologistRemoteDataSource = PsychologistRemoteDataSource();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiBlocProvider(
      providers: [
        RepositoryProvider<ArticleRepository>(
          create: (context) => ArticleRepository(baseUrl: ApiConstants.baseUrl),
        ),

        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            signInUseCase: signInUseCase,
            registerUserUseCase: registerUserUseCase,
            firestore: FirebaseFirestore.instance,
          )..add(const AuthStarted()),
        ),

        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(chatRepository, AiChatApiService()),
        ),

        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit(themeService)),

        BlocProvider<PsychologistInfoBloc>(
          create: (context) => PsychologistInfoBloc(
            psychologistRepository: PsychologistRepositoryImpl(
              psychologistRemoteDataSource,
            ),
          ),
        ),

        BlocProvider<AppointmentBloc>(create: (context) => AppointmentBloc()),

        BlocProvider<PsychologistBloc>(
          create: (context) =>
              PsychologistBloc(repository: PsychologistRepository()),
        ),

        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(
            notificationRepository: NotificationRepository(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  // Elimina el Future.delayed.
  final type = data['type'] as String?;

  switch (type) {
    case 'appointment_created':
    case 'appointment_confirmed':
    case 'appointment_cancelled':
      _navigateToAppointments(context, data);
      break;

    case 'subscription_activated':
    case 'payment_succeeded':
    case 'payment_failed':
      _navigateToProfile(context, data);
      break;

    case 'session_started':
    case 'session_completed':
      _navigateToActiveSession(context, data);
      break;

    case 'session_rated':
      _navigateToAppointments(context, data);
      break;

    default:
      _navigateToNotifications(context);
      break;
  }
}

void _navigateToAppointments(BuildContext context, Map<String, dynamic> data) {
  // Implementar navegación específica a citas
  // Por ejemplo, si tienes una ruta nombrada:
  // Navigator.of(context).pushNamed('/appointments', arguments: data);

  // Por ahora, imprime para debug
  print('Navegar a citas con data: $data');

  // También puedes mostrar la lista de notificaciones como fallback
  _navigateToNotifications(context);
}

void _navigateToProfile(BuildContext context, Map<String, dynamic> data) {
  // Implementar navegación a perfil/premium
  print('Navegar a perfil con data: $data');
  _navigateToNotifications(context);
}

void _navigateToActiveSession(BuildContext context, Map<String, dynamic> data) {
  // Implementar navegación a sesión activa
  print('Navegar a sesión activa con data: $data');
  _navigateToNotifications(context);
}

void _navigateToNotifications(BuildContext context) {
  // Implementar navegación a lista de notificaciones
  // Navigator.of(context).pushNamed('/notifications');
  print('Navegar a lista de notificaciones');
}

/// La clase principal de la aplicación, donde se define el tema y la navegación global.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Suscripción al estado de autenticación para escuchar los cambios del usuario
  late StreamSubscription<User?> _authStateSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Suscribirse a los cambios de estado de autenticación de Firebase
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (user != null) {
        // Usuario ha iniciado sesión
        _setupUserPresence(user.uid);

        _loadUserNotifications();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          // App viene del background - actualizar presencia y cargar notificaciones
          _setupUserPresence(currentUser.uid);
          _loadUserNotifications();
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          // App va al background - marcar como offline
          _setUserOffline(currentUser.uid);
          break;
        case AppLifecycleState.detached:
          _setUserOffline(currentUser.uid);
          break;
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _setUserOffline(currentUser.uid);
    }

    _authStateSubscription.cancel();
    super.dispose();
  }

  void _setUserOffline(String userId) {
    FirebaseFirestore.instance.collection('users').doc(userId).set({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _loadUserNotifications() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Disparar evento para cargar notificaciones
      context.read<NotificationBloc>().add(
        LoadNotifications(
          userId: FirebaseAuth.instance.currentUser!.uid,
          userToken: String.fromCharCode(0),
          userType: String.fromCharCode(0),
        ),
      );
    }
  }

  // Método que configura el estado de presencia del usuario
  void _setupUserPresence(String userId) async {
    final userRealtimeRef = FirebaseDatabase.instance.ref('status/$userId');

    // 1. Establecer el estado inicial en línea en Realtime Database
    await userRealtimeRef.set({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    });

    // 2. Configurar la función onDisconnect en Realtime Database
    userRealtimeRef.onDisconnect().set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  // --- Temas de la aplicación usando FlexColorScheme ---
  ThemeData _lightTheme() {
    final lightColorScheme = FlexColorScheme.light(scheme: FlexScheme.tealM3);
    return FlexThemeData.light(
      scheme: FlexScheme.tealM3,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        bottomNavigationBarElevation: 0,
        navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
        navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurfaceVariant,
        navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
        navigationBarBackgroundSchemeColor: SchemeColor.surface,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: 'Poppins',
    ).copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: lightColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightColorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightColorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: lightColorScheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColorScheme.surface,
        selectedItemColor: lightColorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.normal,
        ),
      ),
      scaffoldBackgroundColor: lightColorScheme.surface,
    );
  }

  ThemeData _darkTheme() {
    final darkColorScheme = FlexColorScheme.dark(scheme: FlexScheme.tealM3);
    return FlexThemeData.dark(
      scheme: FlexScheme.tealM3,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        bottomNavigationBarElevation: 0,
        navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
        navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurfaceVariant,
        navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
        navigationBarBackgroundSchemeColor: SchemeColor.surface,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: 'Poppins',
    ).copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkColorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkColorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColorScheme.surface,
        selectedItemColor: darkColorScheme.primary,
        unselectedItemColor: Colors.grey[400],
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.normal,
        ),
      ),
      scaffoldBackgroundColor: darkColorScheme.surface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: themeState.selectedTheme.themeMode,
          navigatorKey: navigatorKey,
          home: const AuthWrapper(),
          //const AdminPanel(),
        );
      },
    );
  }
}
