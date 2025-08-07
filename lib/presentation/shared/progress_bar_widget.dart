import 'package:flutter/material.dart';

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
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              flex: flexEmpty,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          stepText,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
