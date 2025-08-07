import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para obtener el token de Firebase Auth
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

// Importaciones de las capas de la arquitectura limpia
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/repositories/auth_repository_impl.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/sign_in_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/register_user_usecase.dart';

// Importaciones de las vistas y Blocs/Cubits
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_wrapper.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/chat/bloc/chat_bloc.dart';
import 'package:ai_therapy_teteocan/data/repositories/chat_repository.dart';

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

  const bool useEmulator = true;
  if (useEmulator) {
    await _connectToFirebaseEmulator();
  }

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
  ); // --- Inicialización del Repositorio de Chat ---
  final ChatRepository chatRepository = ChatRepository();

  // --- Inicialización del Servicio de Tema ---
  final ThemeService themeService = ThemeService();

  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      final idToken = await user.getIdToken();
      chatRepository.setAuthToken(idToken);
      log(
        '🔑 Token de Firebase Auth actualizado en ChatRepository para ${user.uid}',
      );
    } else {
      chatRepository.setAuthToken(
        null,
      ); // Limpia el token si el usuario cierra sesión
      log(
        '❌ Usuario desautenticado, token de Firebase Auth limpiado del ChatRepository.',
      );
    }
  });

  runApp(
    MultiBlocProvider(
      providers: [
        // Proveedor para HomeContentCubit
        BlocProvider<HomeContentCubit>(create: (context) => HomeContentCubit()),

        // Proveedor para AuthBloc
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(
                authRepository: authRepository,
                signInUseCase: signInUseCase,
                registerUserUseCase: registerUserUseCase,
              )..add(
                const AuthStarted(),
              ), // Dispara el evento inicial de autenticación
        ),

        // Proveedor para ChatBloc
        BlocProvider<ChatBloc>(create: (context) => ChatBloc(chatRepository)),

        // Proveedor para ThemeCubit
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit(themeService)),
      ],
      child: const MyApp(),
    ),
  );
}

/// Función para conectar la aplicación a los emuladores de Firebase.
Future<void> _connectToFirebaseEmulator() async {
  try {
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    log('🔧 Firebase Auth conectado al emulador en 10.0.2.2:9099');
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
    log('🔧 Firebase Firestore conectado al emulador en 10.0.2.2:8080');
  } catch (e) {
    log('❌ Error conectando a los emuladores: $e');
  }
}

/// La clase principal de la aplicación, donde se define el tema y la navegación global.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      // Configuración específica para AppBar
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
      // Configuración específica para BottomNavigationBar
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
      // Configuración de scaffold
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
      // Configuración específica para AppBar en modo oscuro
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
      // Configuración específica para BottomNavigationBar en modo oscuro
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
      // Configuración de scaffold en modo oscuro
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
          home:
              PsychologistHomeScreen(), // AuthWrapper maneja la navegación inicial
        );
      },
    );
  }
}
