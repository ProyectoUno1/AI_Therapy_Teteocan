import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

class ProgressBarWidget extends StatelessWidget {
  final String stepText;
  final int currentStep; // Ejemplo: 1, 2, 3
  final int totalSteps; // Ejemplo: 3

  const ProgressBarWidget({
    Key? key,
    required this.stepText,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = currentStep / totalSteps;

    // Para evitar que flex sea 0, usamos un mínimo de 1
    int flexFilled = (progress * 100).clamp(1, 100).toInt();
    int flexEmpty = 100 - flexFilled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: flexFilled,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              flex: flexEmpty,
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
        const SizedBox(height: 10),
        Text(
          stepText,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
