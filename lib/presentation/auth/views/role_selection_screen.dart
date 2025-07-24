import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/register_patient_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/register_psychologist_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/progress_bar_widget.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quitamos backgroundColor para que el Stack maneje el fondo
      body: Stack(
        children: [
          // Manchas grandes de fondo
          Align(
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: const Offset(300, 0),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color.fromARGB(178, 130, 196, 195),
                      Color(0x005ca0ac),
                    ],
                    radius: 0.55,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.translate(
              offset: const Offset(100, 100),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color.fromARGB(193, 92, 160, 172),
                      Color(0x0082c4c3),
                    ],
                    radius: 0.55,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Transform.translate(
              offset: const Offset(-120, 80),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.fromARGB(136, 59, 113, 111),
                      const Color.fromARGB(64, 223, 253, 253),
                    ],
                    radius: 0.6,
                  ),
                ),
              ),
            ),
          ),

          // Contenido principal con padding
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  ProgressBarWidget(
                    stepText: 'Primer paso',
                    currentStep: 1,
                    totalSteps: 2,
                  ),
                  const SizedBox(height: 40),
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 90,
                    color: AppConstants.accentColor,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '¿Cómo deseas utilizar Aurora?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Botón Paciente
                  _buildGradientButton(
                    icon: Icons.favorite_rounded,
                    text: 'Paciente',
                    onTap: () =>
                        _navigateToRegister(context, RegisterPatientScreen()),
                  ),
                  const SizedBox(height: 30),

                  // Botón Psicólogo
                  _buildGradientButton(
                    icon: Icons.psychology_alt_rounded,
                    text: 'Psicólogo',
                    onTap: () => _navigateToRegister(
                      context,
                      RegisterPsychologistScreen(),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 4,
          backgroundColor: null,
          shadowColor: Colors.black38,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF82c4c3), Color(0xFF5ca0ac)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext context, Widget nextPage) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}
