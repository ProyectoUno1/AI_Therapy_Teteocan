import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart'
    as auth_provider; // Alias para evitar conflicto de nombres
import 'screens/auth/login_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/psychologist/psychologist_home_screen.dart';
import 'splash_screen.dart'; // Tu SplashScreen


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w300,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      // Input decoration theme para los campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(
          0xFF82C4C3,
        ), // lightAccentColor para los campos de texto
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
        hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        prefixIconColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w300,
          color: Color(0xFFE0E0E0),
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          color: Color(0xFFBDBDBD),
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Color(0xFFBDBDBD),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF2D2D2D),
      ),
      // Input decoration theme para los campos de texto en modo oscuro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(
          0xFF5CA0AC,
        ), // accentColor para los campos de texto en modo oscuro
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
        hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        prefixIconColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        title: 'Aurora AI Therapy App',
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: ThemeMode.system,
        home: PatientHomeScreen(), // Inicia con SplashScreen
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el estado de autenticación de Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostrar SplashScreen o indicador de carga inicial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen(); // O un CircularProgressIndicator en el centro
        }

        // Si el usuario está autenticado
        if (snapshot.hasData && snapshot.data != null) {
          final User? user = snapshot.data;
          // Si el usuario está autenticado, intentar obtener su rol
          return FutureBuilder<String>(
            // TODO: Implementa esta función en tu AuthProvider o un servicio de usuario
            // para obtener el rol del usuario desde tu backend (PostgreSQL) o Firestore.
            // Por ahora, es un placeholder.
            future: _getUserRole(user!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4DB6AC),
                      ),
                    ),
                  ),
                );
              }

              if (roleSnapshot.hasError) {
                // Manejar error al obtener el rol
                print(
                  'Error al obtener el rol del usuario: ${roleSnapshot.error}',
                );
                return LoginScreen(); // O una pantalla de error
              }

              final String userRole =
                  roleSnapshot.data ?? 'unknown'; // Rol por defecto

              if (userRole == 'paciente') {
                return PatientHomeScreen();
              } else if (userRole == 'psicologo') {
                return PsychologistHomeScreen();
              } else {
                // Si el rol no es reconocido o es 'unknown', redirigir al login
                // Considera también cerrar sesión si el rol es inválido.
                print('Rol de usuario no reconocido: $userRole');
                return LoginScreen();
              }
            },
          );
        } else {
          // Si no hay usuario autenticado, mostrar la pantalla de login
          return LoginScreen();
        }
      },
    );
  }

  // TODO: Esta es una función placeholder. DEBES implementarla en tu AuthProvider o un servicio
  // que consulte tu backend (Node.js/PostgreSQL) o Firestore para obtener el rol del usuario.
  // Recibe el Firebase UID del usuario autenticado.
  Future<String> _getUserRole(String firebaseUid) async {
    // Ejemplo de cómo podrías obtener el rol desde Firestore:
    /*
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUid).get();
    if (userDoc.exists) {
      return userDoc.get('role'); // Asume que tienes un campo 'role' en tu documento de usuario
    }
    return 'unknown'; // Si el documento no existe o no tiene rol
    */

    // Ejemplo de cómo podrías obtener el rol desde tu backend Node.js:
    /*
    final response = await http.get(
      Uri.parse('http://YOUR_NODEJS_BACKEND_IP_OR_DOMAIN:PORT/api/user-role/$firebaseUid'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['role'];
    } else {
      print('Error al obtener rol del backend: ${response.body}');
      return 'unknown';
    }
    */

    // --- SIMULACIÓN PARA PRUEBAS SIN BACKEND ---
    // Puedes cambiar esto para simular un rol específico durante el desarrollo
    await Future.delayed(Duration(seconds: 1)); // Simula una llamada a la red
    if (firebaseUid.startsWith('patient')) {
      // Ejemplo: si el UID empieza con 'patient'
      return 'paciente';
    } else if (firebaseUid.startsWith('psychologist')) {
      // Ejemplo: si el UID empieza con 'psychologist'
      return 'psicologo';
    }
    return 'paciente'; // Por defecto para pruebas si no coincide
    // --- FIN SIMULACIÓN ---
  }
}

