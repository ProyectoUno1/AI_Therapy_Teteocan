import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_event.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  final String userRole; 

  const TermsAndConditionsScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  bool _isAccepted = false;
  bool _isLoading = false;

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);

    try {
      context.read<AuthBloc>().add(
        AuthAcceptTermsAndConditions(
          userRole: widget.userRole,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aceptar términos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _declineTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Términos requeridos',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Debes aceptar los términos y condiciones para poder usar la aplicación.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con degradado
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
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 80,
                        color: const Color(0xFF82c4c3),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Por favor, lee y acepta nuestros términos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            'Aceptación de términos',
                            'Al usar esta aplicación, aceptas estar sujeto a estos términos y condiciones. Si no estás de acuerdo, no podrás utilizar nuestros servicios.',
                          ),
                          _buildSection(
                            'Uso de la plataforma',
                            'Te comprometes a usar la plataforma de manera responsable y ética, respetando la confidencialidad y privacidad de todos los usuarios.',
                          ),
                          _buildSection(
                            'Privacidad y datos personales',
                            'Tus datos personales serán tratados conforme a nuestra política de privacidad. No compartiremos tu información con terceros sin tu consentimiento.',
                          ),
                          _buildSection(
                            'Confidencialidad',
                            'Toda la información compartida en sesiones terapéuticas es estrictamente confidencial y está protegida por secreto profesional.',
                          ),
                          _buildSection(
                            'Responsabilidades',
                            'Los usuarios son responsables de mantener la seguridad de sus cuentas y de la veracidad de la información proporcionada.',
                          ),
                          _buildSection(
                            'Modificaciones',
                            'Nos reservamos el derecho de modificar estos términos en cualquier momento. Las modificaciones entrarán en vigor inmediatamente después de su publicación.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Checkbox y botones
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Checkbox de aceptación
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isAccepted,
                              onChanged: (value) {
                                setState(() => _isAccepted = value ?? false);
                              },
                              activeColor: const Color(0xFF82c4c3),
                            ),
                            Expanded(
                              child: Text(
                                'He leído y acepto los términos y condiciones',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón de aceptar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isAccepted && !_isLoading
                              ? _acceptTerms
                              : _declineTerms,
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            backgroundColor: null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isAccepted
                                    ? [
                                        const Color(0xFF82c4c3),
                                        const Color(0xFF5ca0ac)
                                      ]
                                    : [Colors.grey, Colors.grey],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Aceptar y continuar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}