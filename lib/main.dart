// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';
import 'package:timezone/data/latest.dart' as tzdata;

// Importaciones de las capas de la arquitectura limpia
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/repositories/auth_repository_impl.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/sign_in_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/register_user_usecase.dart';
import 'package:ai_therapy_teteocan/data/datasources/psychologist_remote_datasource.dart';

// Importaciones de las vistas y Blocs/Cubits
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_wrapper.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/psychologist_info_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/psychologist_repository_impl.dart';

// Importaciones para el tema
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_state.dart';
import 'package:ai_therapy_teteocan/core/services/theme_service.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Punto de entrada principal de la aplicación.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  
  // --- Inicialización de la base de datos de zonas horarias ---
  tzdata.initializeTimeZones();

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



  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<HomeContentCubit>(create: (context) => HomeContentCubit()),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            signInUseCase: signInUseCase,
            registerUserUseCase: registerUserUseCase,
          )..add(const AuthStarted()),
        ),
        BlocProvider<ChatBloc>(create: (context) => ChatBloc(chatRepository)),
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit(themeService)),
        BlocProvider<PsychologistInfoBloc>(
          create: (context) => PsychologistInfoBloc(
            psychologistRepository: PsychologistRepositoryImpl(
              psychologistRemoteDataSource,
            ),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}



/// La clase principal de la aplicación, donde se define el tema y la navegación global.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Establece el estado inicial en línea si el usuario ya está autenticado
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    // Al cerrar la app, establece el estado a fuera de línea
    _updateOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // El usuario volvió a la aplicación, lo ponemos en línea
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused) {
      // El usuario salió de la aplicación, lo ponemos fuera de línea
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      userRef
          .set({
            'isOnline': isOnline,
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .catchError(
            (error) => log('Error al actualizar el estado de conexión: $error'),
          );
    }
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
          home: const AuthWrapper(), //AuthWrapper maneja la vista dinamicamente
          //const PsychologistHomeScreen(),
          //const PsychologistChatListScreen(),
        );
      },
    );
  }
}