import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/presentation/patient/views/subscription_screen.dart';

class AiUsageLimitIndicator extends StatelessWidget {
  final int used;
  final int limit;
  final bool isPremium;

  const AiUsageLimitIndicator({
    super.key,
    required this.used,
    required this.limit,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (limit == 0) ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final remaining = (limit - used).clamp(0, limit);
    final isNearLimit = percent >= 0.8 && percent < 1.0;
    final isAtLimit = percent >= 1.0;
    final color = isAtLimit
        ? Colors.red
        : isNearLimit
        ? Colors.orange
        : Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              isPremium ? 'Límite de IA (Premium)' : 'Límite de IA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Text(
              isAtLimit ? '¡Límite alcanzado!' : '$remaining de $limit',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (isAtLimit)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium
                      ? 'Has alcanzado el límite de uso de IA para tu plan premium.'
                      : 'Has alcanzado el límite de uso de IA para tu plan gratuito.',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (!isPremium)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontFamily: 'Poppins'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.upgrade),
                      label: const Text('Mejorar mi plan'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          )
        else if (isNearLimit)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isPremium
                        ? 'Estás cerca de tu límite de IA premium.'
                        : 'Estás cerca de tu límite de IA gratuito. Considera mejorar tu plan.',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (!isPremium)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        textStyle: const TextStyle(fontFamily: 'Poppins'),
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.upgrade, size: 18),
                      label: const Text('Mejorar'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
