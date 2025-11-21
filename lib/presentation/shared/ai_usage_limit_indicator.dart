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

  // Función para obtener tamaño de fuente responsivo
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375; // 375 es el ancho base (iPhone SE/8)
    return (baseSize * scale).clamp(baseSize * 0.85, baseSize * 1.15);
  }

  // Función para obtener padding responsivo
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    } else if (width < 400) {
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 11);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  // Función para obtener tamaño de icono responsivo
  double _getResponsiveIconSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.9;
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return _buildPremiumIndicator(context);
    } else {
      return _buildFreeTierIndicator(context);
    }
  }

  Widget _buildPremiumIndicator(BuildContext context) {
    final iconSize = _getResponsiveIconSize(context, compact ? 18 : 22);
    final fontSize = _getResponsiveFontSize(context, compact ? 13 : 15);
    
    return Container(
      padding: _getResponsivePadding(context),
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
            size: iconSize,
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Flexible(
            child: Text(
              'Premium - Sin límites',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
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

    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = _getResponsiveIconSize(context, compact ? 16 : 20);
    final titleFontSize = _getResponsiveFontSize(context, compact ? 12 : 14);
    final counterFontSize = _getResponsiveFontSize(context, compact ? 12 : 14);
    final subtitleFontSize = _getResponsiveFontSize(context, compact ? 11 : 12);

    return Container(
      padding: _getResponsivePadding(context),
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
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy, color: color, size: iconSize),
                    SizedBox(width: screenWidth * 0.02),
                    Flexible(
                      child: Text(
                        'Mensajes disponibles',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                '$used/$limit',
                style: TextStyle(
                  color: isAtLimit ? Colors.orange[800] : Colors.grey[600],
                  fontSize: counterFontSize,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.02),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  height: 8,
                  width: screenWidth * percent * 0.85, // Ajustado para ser más responsivo
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
          ),
          SizedBox(height: screenWidth * 0.015),
          if (isAtLimit)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Límite alcanzado',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  'Has alcanzado el límite de uso de IA para tu plan gratuito.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (!compact)
                  Padding(
                    padding: EdgeInsets.only(top: screenWidth * 0.02),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: _getResponsiveFontSize(context, compact ? 11 : 13),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.upgrade, size: _getResponsiveIconSize(context, 18)),
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
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Estás cerca de tu límite de IA gratuito. Considera mejorar tu plan.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    if (!compact && screenWidth > 360)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            textStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: _getResponsiveFontSize(context, 12),
                            ),
                            side: const BorderSide(color: Colors.orange),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(Icons.upgrade, size: _getResponsiveIconSize(context, 16)),
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
                if (!compact && screenWidth <= 360)
                  Padding(
                    padding: EdgeInsets.only(top: screenWidth * 0.02),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          textStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: _getResponsiveFontSize(context, 12),
                          ),
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.upgrade, size: _getResponsiveIconSize(context, 16)),
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
                  ),
              ],
            )
          else
            Text(
              '$remaining mensajes restantes',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ),
    );
  }
}