import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/screens/auth/register_patient_screen.dart';
import 'package:ai_therapy_teteocan/screens/auth/register_psychologist_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  // Colores de tu paleta
  final Color primaryColor = Color(0xFF3B716F);
  final Color accentColor = Color(0xFF5CA0AC);
  final Color lightAccentColor = Color(0xFF82C4C3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () {
            Navigator.of(
              context,
            ).pop(); // Regresar a la pantalla anterior (Login)
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Barra de progreso y texto "Primer paso"
            _buildProgressBar(context, 'Primer paso'),
            SizedBox(height: 40),

            // Icono superior
            Icon(
              Icons.person_add, // O un icono más representativo si tienes uno
              size: 80,
              color: accentColor,
            ),
            SizedBox(height: 40),

            // Texto "¿Cómo deseas utilizar Aurora?"
            Text(
              '¿Cómo deseas utilizar Aurora?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 60),

            // Botón "Paciente"
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToRegister(context, 'patient');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Paciente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Botón "Psicólogo"
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToRegister(context, 'psychologist');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  'Psicólogo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            Spacer(), // Empuja el contenido hacia arriba
          ],
        ),
      ),
    );
  }

  // Widget para la barra de progreso
  Widget _buildProgressBar(BuildContext context, String stepText) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 1, // Parte completada
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              flex: 1, // Parte por completar
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            stepText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  // Función para navegar a la pantalla de registro con animación
  void _navigateToRegister(BuildContext context, String role) {
    Widget nextPage;
    if (role == 'patient') {
      nextPage = RegisterPatientScreen();
    } else {
      nextPage = RegisterPsychologistScreen();
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Viene desde la derecha
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
