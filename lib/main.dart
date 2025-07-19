import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as auth_provider;
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configurar Firebase Emulator para desarrollo
  const bool useEmulator = true; // Cambia a false en producción
  if (useEmulator) {
    await _connectToFirebaseEmulator();
  }
  
  runApp(MyApp());
}

Future<void> _connectToFirebaseEmulator() async {
  try {
    // Conectar Firebase Auth al emulator
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    print('🔧 Firebase Auth conectado al emulator en localhost:9099');
  } catch (e) {
    print('❌ Error conectando al emulator: $e');
    // Continuar sin emulator si falla la conexión
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
        seedColor: const Color(0xFF4DB6AC), // Teal suave
        brightness: Brightness.light,
        primary: const Color(0xFF4DB6AC),
        secondary: const Color(0xFF81C784), // Verde suave
        surface: const Color(0xFFFAFAFA), // Blanco cálido
        error: const Color(0xFFE57373), // Rojo suave
      ),
      
      // Configuración de texto con Poppins
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300),
        displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
      
      // AppBar con diseño suave
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Botones con esquinas redondeadas
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4DB6AC),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
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
        seedColor: const Color(0xFF4DB6AC),
        brightness: Brightness.dark,
        primary: const Color(0xFF80CBC4), // Teal más claro para contraste
        secondary: const Color(0xFFA5D6A7), // Verde más claro
        surface: const Color(0xFF1E1E1E), // Gris oscuro cálido
        error: const Color(0xFFEF9A9A), // Rojo suave para modo oscuro
      ),
      
      // Configuración de texto para modo oscuro
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, color: Color(0xFFE0E0E0)),
        displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFE0E0E0)),
        displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFE0E0E0)),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFE0E0E0)),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFE0E0E0)),
        headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        bodyLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFE0E0E0)),
        bodyMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFE0E0E0)),
        bodySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Color(0xFFBDBDBD)),
        labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        labelMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        labelSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Color(0xFFBDBDBD)),
      ),
      
      // AppBar para modo oscuro
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2D2D),
        foregroundColor: Color(0xFF80CBC4),
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF80CBC4),
        ),
      ),
      
      // Botones para modo oscuro
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF80CBC4),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF2D2D2D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aurora AI Therapy App',        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: ThemeMode.system,
        home: SplashScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, authProvider, child) {
        // Mostrar pantalla de carga si está procesando
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
              ),
            ),
          );
        }
        
        // Mostrar Home si está autenticado, Login si no
        if (authProvider.isAuthenticated) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
