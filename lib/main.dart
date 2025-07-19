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
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Aurora AI Therapy App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          fontFamily: 'Poppins',
        ),
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
