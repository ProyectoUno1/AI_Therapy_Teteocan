import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as auth_provider;

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


