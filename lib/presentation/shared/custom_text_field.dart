import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

// Widget personalizado para campos de texto con estilo configurable
class CustomTextField extends StatelessWidget {
  // Controlador para manejar el texto ingresado
  final TextEditingController controller;

  // Texto de sugerencia que aparece cuando el campo está vacío
  final String hintText;

  // Icono que se muestra al inicio del campo
  final IconData icon;

  // Tipo de teclado que se muestra (texto, email, número, etc.)
  final TextInputType keyboardType;

  // Indica si el texto debe ocultarse (para contraseñas)
  final bool obscureText;

  // Función para alternar la visibilidad del texto (contraseña)
  final VoidCallback? toggleVisibility;

  // Función para validar el texto ingresado
  final String? Function(String?)? validator;

  // Color para el texto del placeholder (sugerencia)
  final Color? placeholderColor;

  // Si el campo es solo lectura
  final bool? readOnly;

  // Acción al tocar el campo (por ejemplo, abrir un selector de fecha)
  final VoidCallback? onTap;

  // Indica si el campo tiene fondo relleno
  final bool filled;

  // Color de fondo del campo
  final Color? fillColor;

  // Radio de borde para esquinas redondeadas
  final double borderRadius;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.toggleVisibility,
    this.validator,
    this.filled = false,
    this.fillColor,
    this.borderRadius = 8.0,
    this.placeholderColor,
    this.readOnly,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Contenedor que aplica color de fondo y bordes redondeados
      decoration: BoxDecoration(
        color: filled
            ? fillColor ?? Colors.white  // si está relleno usa fillColor o blanco
            : AppConstants.lightAccentColor, // si no, color claro definido en constantes
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: 1,
        style: TextStyle(
          color: filled ? Colors.black87 : Colors.white, // color del texto según fondo
          fontFamily: 'Poppins',
        ),
        validator: validator,
        readOnly: readOnly ?? false,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: placeholderColor ?? Colors.black, // color del placeholder
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(icon, color: filled ? Colors.black54 : Colors.white),
          suffixIcon: toggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: filled ? Colors.black54 : Colors.white,
                  ),
                  onPressed: toggleVisibility, // botón para mostrar/ocultar texto
                )
              : null,
          filled: filled,
          fillColor: fillColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none, // sin borde por defecto
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppConstants.accentColor, width: 2), // borde cuando está enfocado
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Colors.red, width: 2), // borde en caso de error
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Colors.red, width: 2), // borde en error cuando está enfocado
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          errorStyle: const TextStyle(fontSize: 12, color: Colors.red), // estilo para texto de error
        ),
      ),
    );
  }
}

