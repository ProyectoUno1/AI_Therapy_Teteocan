import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/utils/responsive_utils.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/register_patient_screen.dart';
import 'package:ai_therapy_teteocan/presentation/auth/views/register_psychologist_screen.dart';
import 'package:ai_therapy_teteocan/presentation/shared/progress_bar_widget.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

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
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 205, 223, 222),
                  Color.fromARGB(255, 147, 213, 207),
                ],
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.getHorizontalPadding(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // AppBar
                            SizedBox(
                              height: kToolbarHeight,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_back_ios,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.6),
                                      size: ResponsiveUtils.getIconSize(context, 22),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.02),

                            // Progress bar
                            ProgressBarWidget(
                              stepText: 'Primer paso',
                              currentStep: 1,
                              totalSteps: 2,
                            ),

                            SizedBox(height: constraints.maxHeight * 0.04),

                            // Ícono
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              size: ResponsiveUtils.getIconSize(context, 70),
                              color: Theme.of(context).colorScheme.primary,
                            ),

                            SizedBox(height: constraints.maxHeight * 0.03),

                            // Título
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '¿Cómo deseas utilizar Aurora?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, 22),
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.headlineMedium?.color,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),

                            SizedBox(height: constraints.maxHeight * 0.06),

                            // Botón Paciente
                            _buildGradientButton(
                              context: context,
                              icon: Icons.favorite_rounded,
                              text: 'Paciente',
                              onTap: () => _navigateToRegister(
                                context,
                                const RegisterPatientScreen(),
                              ),
                            ),

                            SizedBox(height: isMobile ? 20 : 24),

                            // Botón Psicólogo
                            _buildGradientButton(
                              context: context,
                              icon: Icons.psychology_alt_rounded,
                              text: 'Psicólogo',
                              onTap: () => _navigateToRegister(
                                context,
                                const RegisterPsychologistScreen(),
                              ),
                            ),

                            // Espaciado flexible
                            SizedBox(height: constraints.maxHeight * 0.08),

                            // Footer
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'AURORA',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, 10),
                                  color: Colors.black26,
                                  letterSpacing: 2.0,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveUtils.getButtonHeight(context) * 1.2,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 4,
          backgroundColor: null,
          shadowColor: Colors.black38,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 24),
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF82c4c3), Color(0xFF5ca0ac)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, 24),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveUtils.getIconSize(context, 28),
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context, 18),
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
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}