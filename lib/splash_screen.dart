import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animación de fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _fadeController.forward();

    // Inicializar el AuthBloc para verificar autenticación
    context.read<AuthBloc>().add(const AuthStarted());

    // Timer de respaldo
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthStarted());
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // Calcular tamaños de logo basados en el dispositivo
    double logoSize;
    if (isMobile) {
      logoSize = screenHeight * 0.25; // 25% de la altura en móvil
    } else if (ResponsiveUtils.isTablet(context)) {
      logoSize = screenHeight * 0.3; // 30% en tablet
    } else {
      logoSize = screenHeight * 0.35; // 35% en desktop
    }
    
    // Limitar el tamaño máximo y mínimo
    logoSize = logoSize.clamp(150.0, 300.0);

    return Scaffold(
      backgroundColor: const Color(0xFF82C4C3),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView( // ← AÑADIDO: Previene overflow
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // ← AÑADIDO: Evita que el Column ocupe toda la altura
                  children: [
                    // Logo con tamaño responsive y manejo de errores
                    _buildLottieLogo(logoSize),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Indicator
                    SizedBox(
                      width: isMobile ? 40 : 50,
                      height: isMobile ? 40 : 50,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Título
                    Text(
                      'Aurora AI Therapy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getFontSize(context, 24),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtítulo
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: ResponsiveUtils.getFontSize(context, 16),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ← AÑADIDO: Método para manejar el logo Lottie con error handling
  Widget _buildLottieLogo(double logoSize) {
    try {
      return Lottie.asset(
        "assets/logoAurora.json",
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderLogo(logoSize);
        },
      );
    } catch (e) {
      return _buildPlaceholderLogo(logoSize);
    }
  }

  // ← AÑADIDO: Placeholder si el Lottie falla
  Widget _buildPlaceholderLogo(double logoSize) {
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        Icons.psychology,
        size: logoSize * 0.6,
        color: Colors.white,
      ),
    );
  }
}