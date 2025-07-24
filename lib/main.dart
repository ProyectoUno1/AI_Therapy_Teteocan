import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart'
    as http; // Necesario para UserRemoteDataSourceImpl

// Importaciones de las capas de la arquitectura limpia
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/data/datasources/auth_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/datasources/user_remote_datasource.dart';
import 'package:ai_therapy_teteocan/data/repositories/auth_repository_impl.dart';
import 'package:ai_therapy_teteocan/data/repositories/user_repository_impl.dart';
import 'package:ai_therapy_teteocan/domain/repositories/auth_repository.dart';
import 'package:ai_therapy_teteocan/domain/repositories/user_repository.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/sign_in_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/auth/register_user_usecase.dart';
import 'package:ai_therapy_teteocan/domain/usecases/user/get_user_role_usecase.dart'; // Aunque el rol ya lo trae el repo de auth

// Importaciones de las vistas
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/login_screen.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/patient_home_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/psychologist_home_screen.dart';
import 'package:ai_therapy_teteocan/splash_screen.dart'; // Tu SplashScreen

// Asegúrate de que firebase_options.dart esté generado correctamente
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar Firebase Emulator para desarrollo
  const bool useEmulator = true; // Cambia a false en producción
  if (useEmulator) {
    await _connectToFirebaseEmulator();
  }

  // --- Inyección de dependencias (Service Locator simple) ---
  // Inicializar DataSources
  final AuthRemoteDataSource authRemoteDataSource = AuthRemoteDataSourceImpl();
  final UserRemoteDataSource userRemoteDataSource = UserRemoteDataSourceImpl(
    client: http.Client(),
  );

  // Inicializar Repositories
  final AuthRepository authRepository = AuthRepositoryImpl(
    authRemoteDataSource: authRemoteDataSource,
    userRemoteDataSource: userRemoteDataSource,
  );
  final UserRepository userRepository = UserRepositoryImpl(
    remoteDataSource: userRemoteDataSource,
  );

  // Inicializar UseCases
  final SignInUseCase signInUseCase = SignInUseCase(authRepository);
  final RegisterUserUseCase registerUserUseCase = RegisterUserUseCase(
    authRepository,
  );
  final GetUserRoleUseCase getUserRoleUseCase = GetUserRoleUseCase(
    userRepository,
  ); // Se pasa al AuthBloc, pero el AuthRepository ya trae el rol

  runApp(
    // MultiBlocProvider para proporcionar Blocs a todo el árbol de widgets
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(
                authRepository: authRepository,
                signInUseCase: signInUseCase,
                registerUserUseCase: registerUserUseCase,
                // getUserRoleUseCase: getUserRoleUseCase, // No es necesario pasarlo directamente si el repo ya lo maneja
              )..add(
                const AuthUserChanged(),
              ), // Disparar evento inicial para verificar el estado de autenticación
        ),
        // Puedes añadir otros Blocs/Cubits globales aquí si los necesitas
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _connectToFirebaseEmulator() async {
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    print('🔧 Firebase Auth conectado al emulator en localhost:9099');
  } catch (e) {
    print('❌ Error conectando al emulator: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Tema claro con colores suaves y profesionales para terapia psicológica
  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.light,

      // Colores primarios - tonos suaves de verde azulado (calma y serenidad)
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.accentColor, // Usa tu constante
        brightness: Brightness.light,
        primary: AppConstants.accentColor, // Usa tu constante
        secondary: const Color(0xFF81C784), // Verde suave
        surface: const Color(0xFFFAFAFA), // Blanco cálido
        error: AppConstants.errorColor, // Usa tu constante
      ),

      // Configuración de texto con Poppins
      textTheme: _poppinsTextTheme(Brightness.light),

      // AppBar con diseño suave
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.accentColor, // Usa tu constante
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Botones con esquinas redondeadas
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.accentColor, // Usa tu constante
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Cards con sombra suave
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white, // Blanco para modo claro
      ),
      // Input decoration theme para los campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.lightAccentColor, // Usa tu constante
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Poppins',
        ),
        prefixIconColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        errorStyle: const TextStyle(
          height: 0,
          fontSize: 0,
        ), // Para ocultar el texto de error de validación
      ),
    );
  }

  // Tema oscuro con colores cálidos y relajantes
  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,

      // Colores para modo oscuro - tonos cálidos y suaves
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.accentColor, // Usa tu constante
        brightness: Brightness.dark,
        primary: AppConstants.lightAccentColor, // Teal más claro para contraste
        secondary: const Color(0xFFA5D6A7), // Verde más claro
        surface: const Color(0xFF1E1E1E), // Gris oscuro cálido
        error: const Color(0xFFEF9A9A), // Rojo suave para modo oscuro
      ),

      // Configuración de texto para modo oscuro
      textTheme: _poppinsTextTheme(Brightness.dark),

      // AppBar para modo oscuro
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2D2D),
        foregroundColor: AppConstants.lightAccentColor, // Usa tu constante
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppConstants.lightAccentColor, // Usa tu constante
        ),
      ),

      // Botones para modo oscuro
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.lightAccentColor, // Usa tu constante
          foregroundColor: const Color(0xFF1E1E1E),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Cards para modo oscuro
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF2D2D2D), // Gris oscuro para modo oscuro
      ),
      // Input decoration theme para los campos de texto en modo oscuro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants
            .accentColor, // Color más oscuro para campos en modo oscuro
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          color: Colors.white70,
          fontFamily: 'Poppins',
        ),
        prefixIconColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        errorStyle: const TextStyle(
          height: 0,
          fontSize: 0,
        ), // Para ocultar el texto de error de validación
      ),
    );
  }

  // Función auxiliar para el TextTheme de Poppins
  TextTheme _poppinsTextTheme(Brightness brightness) {
    Color textColor = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;
    Color mutedTextColor = brightness == Brightness.light
        ? Colors.black54
        : Colors.grey[400]!;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w300,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        color: mutedTextColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: mutedTextColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        color: mutedTextColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName, // Usa la constante
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      home:
          LoginScreen(), // Usa AuthWrapper para manejar la navegación inicial
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha el estado del AuthBloc para determinar qué pantalla mostrar
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.unknown) {
          // Muestra el SplashScreen mientras el AuthBloc verifica el estado inicial
          return SplashScreen();
        } else if (state.status == AuthStatus.loading) {
          // Muestra un indicador de carga durante operaciones de autenticación
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.accentColor,
                ),
              ),
            ),
          );
        } else if (state.status == AuthStatus.authenticatedPatient) {
          // Redirige al Home del paciente si está autenticado como paciente
          return PatientHomeScreen();
        } else if (state.status == AuthStatus.authenticatedPsychologist) {
          // Redirige al Home del psicólogo si está autenticado como psicólogo
          return PsychologistHomeScreen();
        } else if (state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.error) {
          // Si no está autenticado o hubo un error, muestra la pantalla de Login
          return LoginScreen();
        }
        // Fallback, aunque con los estados bien definidos no debería ser necesario
        return const SplashScreen();
      },
    );
  }
}

