import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final VoidCallback? toggleVisibility;
  final String? Function(String?)? validator;
  final Color? placeholderColor;
  final bool? readOnly;
  final VoidCallback? onTap;

  // Nuevos parámetros para personalizar el fondo y bordes
  final bool filled;
  final Color? fillColor;
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
     
      decoration: BoxDecoration(
        color: filled
            ? fillColor ?? Colors.white
            : AppConstants.lightAccentColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: 1,
        style: TextStyle(
          color: filled ? Colors.black87 : Colors.white,
          fontFamily: 'Poppins',
        ),
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black, fontFamily: 'Poppins'),
          prefixIcon: Icon(icon, color: filled ? Colors.black54 : Colors.white),
          suffixIcon: toggleVisibility != null
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: filled ? Colors.black54 : Colors.white,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          filled: filled,
          fillColor: fillColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: AppConstants.accentColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
        ),
      ),
    );
  }
}
