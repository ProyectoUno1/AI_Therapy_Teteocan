// lib/presentation/shared/progress_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/core/constants/app_constants.dart';

class ProgressBarWidget extends StatelessWidget {
  final String stepText;
  final int currentStep; // 1 o 2
  final int totalSteps; // Generalmente 2

  const ProgressBarWidget({
    super.key,
    required this.stepText,
    required this.currentStep,
    this.totalSteps = 2,
  });

  @override
  Widget build(BuildContext context) {
    double progress = currentStep / totalSteps;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: (progress * 100).toInt(),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Expanded(
              flex: ((1 - progress) * 100).toInt(),
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            stepText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
