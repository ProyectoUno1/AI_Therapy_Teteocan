// lib/presentation/shared/ai_usage_limit_indicator.dart

import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/presentation/subscription/views/subscription_screen.dart';

class AiUsageLimitIndicator extends StatelessWidget {
  final int used;
  final int limit;
  final bool isPremium;
  final bool compact;

  const AiUsageLimitIndicator({
    super.key,
    required this.used,
    required this.limit,
    required this.isPremium,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return _buildPremiumIndicator();
    } else {
      return _buildFreeTierIndicator(context);
    }
  }

  Widget _buildPremiumIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9B0F), Color(0xFF1EBE1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green[800]!.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: compact ? 18 : 22,
          ),
          const SizedBox(width: 8),
          Text(
            'Premium - Sin límites',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeTierIndicator(BuildContext context) {
    final percent = (limit == 0) ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final remaining = (limit - used).clamp(0, limit);
    final isNearLimit = percent >= 0.8 && percent < 1.0;
    final isAtLimit = percent >= 1.0;
    final color = isAtLimit
        ? Colors.red
        : isNearLimit
            ? Colors.orange
            : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtLimit ? Colors.orange[300]! : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy, color: color, size: compact ? 16 : 20),
                  const SizedBox(width: 8),
                  Text(
                    'Mensajes disponibles',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              Text(
                '$used/$limit',
                style: TextStyle(
                  color: isAtLimit ? Colors.orange[800] : Colors.grey[600],
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                height: 8,
                width: MediaQuery.of(context).size.width * percent * 0.7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAtLimit
                        ? [Colors.orange[600]!, Colors.orange[800]!]
                        : [const Color(0xFF4285F4), const Color(0xFF34A853)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isAtLimit)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' Límite alcanzado',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Has alcanzado el límite de uso de IA para tu plan gratuito.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: compact ? 11 : 14,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.upgrade, size: 18),
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
            )
          else if (isNearLimit)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ $remaining mensajes restantes',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Estás cerca de tu límite de IA gratuito. Considera mejorar tu plan.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (!compact)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            textStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: compact ? 11 : 12,
                            ),
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.upgrade, size: 16),
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
              ],
            )
          else
            Text(
              ' $remaining mensajes restantes',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ),
    );
  }
}