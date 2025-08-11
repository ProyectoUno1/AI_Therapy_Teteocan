import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/register_patient_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/register_psychologist_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/progress_bar_widget.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 255, 255, 255), // Teal claro
                  Color.fromARGB(255, 205, 223, 222), // Teal medio
                  Color.fromARGB(255, 147, 213, 207), // Teal más fuerte
                ],
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
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    '¿Cómo deseas utilizar Aurora?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
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
