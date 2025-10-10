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
    // Colores personalizados para mejor visibilidad en modo oscuro
    const darkBackground = Color(0xFF121212); // Fondo muy oscuro
    const darkSurface = Color(0xFF1E1E1E); // Superficie de cards/containers
    const darkSurfaceVariant = Color(0xFF2C2C2C); // Superficie elevada
    const tealPrimary = Color(0xFF4DB6AC); // Teal principal (más brillante)
    const tealSecondary = Color(0xFF80CBC4); // Teal secundario
    const textPrimary = Color(0xFFE0E0E0); // Texto principal (muy legible)
    const textSecondary = Color(0xFFB0B0B0); // Texto secundario
    const borderColor = Color(0xFF3A3A3A); // Bordes visibles

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',

      // Colores base
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: borderColor,
      disabledColor: textSecondary.withOpacity(0.5),
      highlightColor: tealPrimary.withOpacity(0.1),
      splashColor: tealPrimary.withOpacity(0.2),
      hoverColor: tealPrimary.withOpacity(0.1),
      focusColor: tealPrimary.withOpacity(0.2),

      // ColorScheme completo
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary: tealPrimary,
        onPrimary: Colors.black,
        primaryContainer: tealPrimary.withOpacity(0.3),
        onPrimaryContainer: textPrimary,
        secondary: tealSecondary,
        onSecondary: Colors.black,
        secondaryContainer: tealSecondary.withOpacity(0.3),
        onSecondaryContainer: textPrimary,
        tertiary: tealSecondary,
        onTertiary: Colors.black,
        error: Color(0xFFCF6679),
        onError: Colors.black,
        errorContainer: Color(0xFFCF6679).withOpacity(0.3),
        onErrorContainer: textPrimary,
        surface: darkSurface,
        onSurface: textPrimary,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: textSecondary,
        outline: borderColor,
        outlineVariant: Color(0xFF2A2A2A),
        shadow: Colors.black,
        scrim: Colors.black.withOpacity(0.5),
        inverseSurface: textPrimary,
        onInverseSurface: darkBackground,
        inversePrimary: tealPrimary,
      ),

      // Cards con bordes visibles
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.5),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkBackground,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        shadowColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: textPrimary, size: 24),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: tealPrimary,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: tealPrimary.withOpacity(0.3),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: tealPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: textSecondary, fontFamily: 'Poppins');
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: tealPrimary);
          }
          return const IconThemeData(color: textSecondary);
        }),
      ),

      // Input Fields con bordes visibles
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tealPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFCF6679), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor.withOpacity(0.5), width: 1),
        ),
        labelStyle: TextStyle(color: textSecondary, fontFamily: 'Poppins'),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.6),
          fontFamily: 'Poppins',
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Containers y ListTiles
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        leadingAndTrailingTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),

      // Dividers visibles
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Text Theme completo
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 57,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: textSecondary,
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Diálogos con bordes
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        contentTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),

      // Bottom Sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceVariant,
        contentTextStyle: const TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
        ),
        actionTextColor: tealPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealPrimary,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tealPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tealPrimary,
          side: BorderSide(color: tealPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tealPrimary,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Chips con bordes
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        deleteIconColor: textSecondary,
        disabledColor: darkSurface.withOpacity(0.5),
        selectedColor: tealPrimary.withOpacity(0.3),
        secondarySelectedColor: tealSecondary.withOpacity(0.3),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        side: BorderSide(color: borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(color: textPrimary, fontFamily: 'Poppins'),
        secondaryLabelStyle: const TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
        ),
        brightness: Brightness.dark,
      ),

      // Progress Indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: tealPrimary,
        linearTrackColor: darkSurfaceVariant,
        circularTrackColor: darkSurfaceVariant,
      ),

      // Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: tealPrimary,
        inactiveTrackColor: darkSurfaceVariant,
        thumbColor: tealPrimary,
        overlayColor: tealPrimary.withOpacity(0.2),
        valueIndicatorColor: tealPrimary,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary.withOpacity(0.5);
          }
          return darkSurfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(borderColor),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary;
          }
          return textSecondary;
        }),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: tealPrimary,
        unselectedLabelColor: textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: tealPrimary, width: 3),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.normal,
        ),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        textStyle: const TextStyle(color: textPrimary, fontFamily: 'Poppins'),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textPrimary, size: 24),

      primaryIconTheme: const IconThemeData(color: tealPrimary, size: 24),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        textStyle: const TextStyle(color: textPrimary, fontFamily: 'Poppins'),
      ),

      // Badge
      badgeTheme: BadgeThemeData(
        backgroundColor: tealPrimary,
        textColor: Colors.black,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Banner
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: darkSurface,
        contentTextStyle: const TextStyle(
          color: textPrimary,
          fontFamily: 'Poppins',
        ),
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
      ),

      // Time Picker
      timePickerTheme: TimePickerThemeData(
        backgroundColor: darkSurface,
        dialBackgroundColor: darkSurfaceVariant,
        dialHandColor: tealPrimary,
        dialTextColor: textPrimary,
        hourMinuteTextColor: textPrimary,
        dayPeriodTextColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // Date Picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkSurface,
        headerBackgroundColor: tealPrimary,
        headerForegroundColor: Colors.black,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tealPrimary;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(tealPrimary),
        todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
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
