// lib/core/utils/responsive_utils.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class ResponsiveUtils {
  // ✅ BREAKPOINTS BASADOS EN ESTÁNDARES DE DISEÑO
  static const double mobileSmallMaxWidth = 360;
  static const double mobileMaxWidth = 480;
  static const double tabletMaxWidth = 900;
  static const double desktopMaxWidth = 1200;

  

  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }
  
  // ✅ TAMAÑOS MÍNIMOS TÁCTILES
  static const double minTouchTarget = 44.0;
  static const double minTouchTargetMaterial = 48.0;

  // ========== MÉTODOS COMPATIBLES CON VERSIÓN ANTERIOR ==========

  // ✅ PADDING HORIZONTAL - Compatible
  static double getHorizontalPadding(BuildContext context) {
    return getAdaptivePadding(context).left;
  }

  // ✅ PADDING VERTICAL - Compatible
  static double getVerticalPadding(BuildContext context) {
    return getAdaptivePadding(context).top;
  }

  // ✅ ESPACIADO VERTICAL - Compatible
  static double getVerticalSpacing(BuildContext context, double baseSpacing) {
    return getIntelligentVerticalSpacing(context, baseSpacing);
  }

  // ✅ ESPACIADO HORIZONTAL - Compatible
  static double getHorizontalSpacing(BuildContext context, double baseSpacing) {
    final scaleFactor = getDynamicScaleFactor(context);
    return baseSpacing * scaleFactor;
  }

  // ✅ TAMAÑO DE FUENTE - Compatible
  static double getFontSize(BuildContext context, double baseSize) {
    return getResponsiveFontSize(context, baseSize);
  }

  // ✅ LOGO HEIGHT - Compatible
  static double getLogoHeight(BuildContext context) {
    return getIntelligentLogoHeight(context);
  }

  // ✅ LOGO WIDTH - Compatible
  static double getLogoWidth(BuildContext context) {
    return getIntelligentLogoWidth(context);
  }

  // ✅ ICON SIZE - Compatible
  static double getIconSize(BuildContext context, double baseSize) {
    final scaleFactor = getDynamicScaleFactor(context);
    return baseSize * scaleFactor;
  }

  // ✅ BUTTON HEIGHT - Compatible
  static double getButtonHeight(BuildContext context) {
    return getAdaptiveButtonHeight(context);
  }

  // ✅ BORDER RADIUS - Compatible
  static double getBorderRadius(BuildContext context, double baseRadius) {
    return getResponsiveBorderRadius(context, baseRadius);
  }

  // ✅ AVATAR RADIUS - Compatible
  static double getAvatarRadius(BuildContext context, double baseRadius) {
    final scaleFactor = getDynamicScaleFactor(context);
    return baseRadius * scaleFactor;
  }

  // ✅ CARD HEIGHT - Compatible
  static double getCardHeight(BuildContext context, double baseHeight) {
    final scaleFactor = getDynamicScaleFactor(context);
    return baseHeight * scaleFactor;
  }

  // ✅ CARD PADDING - Compatible
  static EdgeInsets getCardPadding(BuildContext context) {
    return getAdaptivePadding(context);
  }

  // ✅ MAX CONTENT WIDTH - Compatible
  static double getMaxContentWidth(BuildContext context) {
    return getIntelligentMaxWidth(context);
  }

  // ✅ LANDSCAPE SCALE FACTOR - Compatible
  static double getLandscapeScaleFactor(BuildContext context) {
    final height = getAvailableHeight(context);
    
    if (height < 350) return 0.75;
    if (height < 400) return 0.82;
    if (height < 500) return 0.88;
    if (height < 600) return 0.92;
    return 1.0;
  }

  // ✅ IS LANDSCAPE MODE - Compatible
  static bool isLandscapeMode(BuildContext context) {
    return isLandscape(context);
  }

  // ========== MÉTODOS NUEVOS MEJORADOS ==========

  // ✅ OBTENER DIMENSIONES DE PANTALLA CON MediaQuery
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  static double getAvailableHeight(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;
    return size.height - padding.top - padding.bottom - viewInsets.bottom;
  }
  
  static double getAvailableWidth(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return size.width - padding.left - padding.right;
  }

  // ✅ OBTENER ORIENTACIÓN
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }
  
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }
  
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }

  // ✅ OBTENER TIPO DE DISPOSITIVO CON LÓGICA AVANZADA
  static DeviceType getDeviceType(BuildContext context) {
    final width = getScreenWidth(context);
    final aspectRatio = width / getScreenHeight(context);
    
    if (width < mobileSmallMaxWidth) {
      return DeviceType.mobileSmall;
    } else if (width < mobileMaxWidth) {
      return DeviceType.mobile;
    } else if (width < tabletMaxWidth) {
      // ✅ DETECCIÓN MEJORADA DE TABLETS POR ASPECT RATIO
      if (aspectRatio > 1.3 && width < 700) {
        return DeviceType.tablet; // Tablet en landscape
      }
      return DeviceType.tablet;
    } else if (width < desktopMaxWidth) {
      return DeviceType.desktop;
    }
    return DeviceType.desktopLarge;
  }

  // ✅ VERIFICADORES CON MediaQuery
  static bool isMobileSmall(BuildContext context) {
    return getScreenWidth(context) < mobileSmallMaxWidth;
  }

  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < mobileMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= tabletMaxWidth;
  }

  // ✅ FACTOR DE ESCALA DINÁMICO BASADO EN DIMENSIONES REALES
  static double getDynamicScaleFactor(BuildContext context) {
    final width = getScreenWidth(context);
    final height = getAvailableHeight(context);
    final landscapeMode = isLandscape(context);
    
    double scale = 1.0;
    
    // ✅ ESCALA BASADA EN ANCHO
    if (width < 320) scale = 0.75;
    else if (width < 360) scale = 0.85;
    else if (width < 400) scale = 0.92;
    else if (width < 480) scale = 0.96;
    else if (width < 600) scale = 0.85;  // Tablets pequeñas
    else if (width < 700) scale = 0.90;
    else if (width < 800) scale = 0.95;
    else if (width < 900) scale = 0.98;
    else if (width >= 1200) scale = 1.1;
    
    // ✅ AJUSTE POR ALTURA DISPONIBLE (IMPORTANTE PARA LANDSCAPE)
    if (landscapeMode && height < 400) {
      scale *= 0.8;
    } else if (landscapeMode && height < 500) {
      scale *= 0.85;
    } else if (landscapeMode && height < 600) {
      scale *= 0.9;
    }
    
    return scale.clamp(0.7, 1.3);
  }

  // ✅ PADDING ADAPTATIVO CON MediaQuery
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    final orientation = getOrientation(context);
    final safeArea = MediaQuery.of(context).padding;
    
    double horizontal, vertical;
    
    if (isMobileSmall(context)) {
      horizontal = 12.0;
      vertical = orientation == Orientation.portrait ? 8.0 : 4.0;
    } else if (isMobile(context)) {
      horizontal = 16.0;
      vertical = orientation == Orientation.portrait ? 12.0 : 6.0;
    } else if (isTablet(context)) {
      horizontal = 20.0;
      vertical = orientation == Orientation.portrait ? 16.0 : 8.0;
    } else {
      horizontal = 24.0;
      vertical = orientation == Orientation.portrait ? 20.0 : 12.0;
    }
    
    // ✅ CONSIDERAR SAFE AREA
    return EdgeInsets.fromLTRB(
      math.max(horizontal, safeArea.left),
      math.max(vertical, safeArea.top),
      math.max(horizontal, safeArea.right),
      math.max(vertical, safeArea.bottom),
    );
  }

  // ✅ ANCHO MÁXIMO INTELIGENTE
  static double getIntelligentMaxWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    final orientation = getOrientation(context);
    
    if (isMobile(context)) {
      return orientation == Orientation.portrait 
          ? screenWidth * 0.92
          : screenWidth * 0.7;
    } else if (isTablet(context)) {
      return orientation == Orientation.portrait
          ? 400.0
          : 500.0;
    } else {
      return 500.0;
    }
  }

  // ✅ TAMAÑO DE FUENTE RESPONSIVO CON ESCALA DINÁMICA
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final scaleFactor = getDynamicScaleFactor(context);
    final calculatedSize = baseSize * scaleFactor;
    
    // ✅ LÍMITES INTELIGENTES
    final minSize = 8.0;
    final maxSize = baseSize * 1.5;
    
    return calculatedSize.clamp(minSize, maxSize);
  }

  // ✅ ESPACIADO VERTICAL INTELIGENTE
  static double getIntelligentVerticalSpacing(BuildContext context, double baseSpacing) {
    final availableHeight = getAvailableHeight(context);
    final orientation = getOrientation(context);
    final scaleFactor = getDynamicScaleFactor(context);
    
    double spacing = baseSpacing * scaleFactor;
    
    // ✅ AJUSTAR SEGÚN ALTURA DISPONIBLE
    if (availableHeight < 600) {
      spacing *= 0.7;
    } else if (availableHeight < 700) {
      spacing *= 0.8;
    } else if (availableHeight > 1000) {
      spacing *= 1.1;
    }
    
    // ✅ REDUCIR MÁS EN LANDSCAPE
    if (orientation == Orientation.landscape) {
      spacing *= 0.8;
    }
    
    return spacing;
  }

  // ✅ LOGO SCALING INTELIGENTE
  static double getIntelligentLogoHeight(BuildContext context) {
    final availableHeight = getAvailableHeight(context);
    final orientation = getOrientation(context);
    final scaleFactor = getDynamicScaleFactor(context);
    
    double baseHeight;
    
    if (isMobileSmall(context)) {
      baseHeight = 50.0;
    } else if (isMobile(context)) {
      baseHeight = 60.0;
    } else if (isTablet(context)) {
      baseHeight = orientation == Orientation.portrait ? 70.0 : 60.0;
    } else {
      baseHeight = 80.0;
    }
    
    // ✅ AJUSTAR SEGÚN ALTURA DISPONIBLE
    if (availableHeight < 500) {
      baseHeight *= 0.7;
    } else if (availableHeight < 600) {
      baseHeight *= 0.8;
    } else if (availableHeight > 900) {
      baseHeight *= 1.1;
    }
    
    return baseHeight * scaleFactor;
  }

  static double getIntelligentLogoWidth(BuildContext context) {
    final logoHeight = getIntelligentLogoHeight(context);
    // ✅ MANTENER PROPORCIÓN 3:1 APROX
    return logoHeight * 2.5;
  }

  // ✅ BOTÓN HEIGHT ADAPTATIVO
  static double getAdaptiveButtonHeight(BuildContext context) {
    final scaleFactor = getDynamicScaleFactor(context);
    final orientation = getOrientation(context);
    
    double baseHeight = minTouchTargetMaterial;
    
    if (isTablet(context) || isDesktop(context)) {
      baseHeight = 50.0;
    }
    
    if (orientation == Orientation.landscape) {
      baseHeight *= 0.9;
    }
    
    return baseHeight * scaleFactor;
  }

  // ✅ BORDER RADIUS RESPONSIVO
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final scaleFactor = getDynamicScaleFactor(context);
    return baseRadius * scaleFactor;
  }

  // ✅ GRID LAYOUT INTELIGENTE
  static int getIntelligentGridCount(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    final orientation = getOrientation(context);
    
    if (screenWidth < 400) return 1;
    if (screenWidth < 600) return orientation == Orientation.portrait ? 1 : 2;
    if (screenWidth < 900) return orientation == Orientation.portrait ? 2 : 3;
    if (screenWidth < 1200) return 3;
    return 4;
  }

  // ✅ ASPECT RATIO ADAPTATIVO
  static double getAdaptiveAspectRatio(BuildContext context) {
    final orientation = getOrientation(context);
    final screenWidth = getScreenWidth(context);
    
    if (isMobile(context)) {
      return orientation == Orientation.portrait ? 4/3 : 16/9;
    } else if (isTablet(context)) {
      return orientation == Orientation.portrait ? 3/2 : 16/10;
    } else {
      return 16/9;
    }
  }

  // ✅ MÉTODOS ADICIONALES COMPATIBLES
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  static bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 20;
  }

  static EdgeInsets getContentMargin(BuildContext context) {
    return getAdaptivePadding(context);
  }

  static double getDialogWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) return screenWidth * 0.85;
    if (isTablet(context)) return screenWidth * 0.6;
    return 500.0;
  }

  static double getBottomSheetHeight(BuildContext context, double percentage) {
    final screenHeight = getScreenHeight(context);
    return screenHeight * percentage;
  }

  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  static double getResponsiveWidth(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final isLandscapeMode = isLandscape(context);
    final scaleFactor = getLandscapeScaleFactor(context);
    
    double baseWidth;
    if (isDesktop(context)) {
      baseWidth = desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      baseWidth = tablet ?? mobile;
    } else {
      baseWidth = mobile;
    }
    
    return isLandscapeMode ? baseWidth * scaleFactor : baseWidth;
  }

  static double getAdaptiveHorizontalPadding(BuildContext context) {
    final basePadding = getHorizontalPadding(context);
    final isLandscapeMode = isLandscape(context);
    
    if (isLandscapeMode) {
      return basePadding * 0.85;
    }
    return basePadding;
  }

  static double getAdaptiveCardHeight(BuildContext context, double baseHeight) {
    final isLandscapeMode = isLandscape(context);
    final scaleFactor = getLandscapeScaleFactor(context);
    
    if (isLandscapeMode) {
      return baseHeight * 0.85 * scaleFactor;
    }
    return getCardHeight(context, baseHeight);
  }

  static int getMaxLines(BuildContext context, int baseLine) {
    final isLandscapeMode = isLandscape(context);
    
    if (isLandscapeMode) {
      return (baseLine * 0.8).round().clamp(1, baseLine);
    }
    
    if (isMobileSmall(context)) return (baseLine * 0.8).round();
    return baseLine;
  }

  static double getKeyboardPadding(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // ✅ MÉTODOS DE CONVENIENCIA PARA LayoutBuilder
  static bool shouldShowCompactLayout(BuildContext context) {
    return getAvailableHeight(context) < 600 || isLandscape(context);
  }
  
  static bool shouldShowWideLayout(BuildContext context) {
    return getScreenWidth(context) > 700;
  }

  // ✅ DEBUG MEJORADO
  static void debugResponsiveInfo(BuildContext context) {
    final width = getScreenWidth(context);
    final deviceType = getDeviceType(context);
    
    debugPrint('📱 Responsive Debug:');
    debugPrint('   • Ancho pantalla: $width');
    debugPrint('   • Tipo dispositivo: $deviceType');
    debugPrint('   • Es mobile: ${isMobile(context)}');
    debugPrint('   • Es tablet: ${isTablet(context)}');
    debugPrint('   • Es desktop: ${isDesktop(context)}');
    debugPrint('   • Padding horizontal: ${getHorizontalPadding(context)}');
    debugPrint('   • Max content width: ${getMaxContentWidth(context)}');
  }

  static void debugAdvancedInfo(BuildContext context) {
    final size = getScreenSize(context);
    final availableSize = Size(getAvailableWidth(context), getAvailableHeight(context));
    final orientation = getOrientation(context);
    final deviceType = getDeviceType(context);
    final scaleFactor = getDynamicScaleFactor(context);
    
    debugPrint('📱 ADVANCED RESPONSIVE DEBUG:');
    debugPrint('   • Screen Size: ${size.width}x${size.height}');
    debugPrint('   • Available Size: ${availableSize.width}x${availableSize.height}');
    debugPrint('   • Orientation: $orientation');
    debugPrint('   • Device Type: $deviceType');
    debugPrint('   • Scale Factor: $scaleFactor');
    debugPrint('   • Safe Area: ${MediaQuery.of(context).padding}');
    debugPrint('   • View Insets: ${MediaQuery.of(context).viewInsets}');
    debugPrint('   • Pixel Ratio: ${MediaQuery.of(context).devicePixelRatio}');
  }
}

enum DeviceType { mobileSmall, mobile, tablet, desktop, desktopLarge }

// 🎯 WIDGETS AVANZADOS CON TÉCNICAS DE RESPONSIVIDAD

class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool useSafeArea;
  final bool constrainWidth;
  final double? maxWidth;
  final double? minHeight;
  final AlignmentGeometry? alignment;

  const AdaptiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.useSafeArea = true,
    this.constrainWidth = true,
    this.maxWidth,
    this.minHeight,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        
        Widget content = Container(
          width: constrainWidth 
              ? (maxWidth ?? ResponsiveUtils.getIntelligentMaxWidth(context))
              : availableWidth,
          height: minHeight != null ? math.max(minHeight!, availableHeight) : null,
          padding: padding ?? ResponsiveUtils.getAdaptivePadding(context),
          alignment: alignment,
          child: child,
        );

        if (useSafeArea) {
          content = SafeArea(
            minimum: ResponsiveUtils.getAdaptivePadding(context),
            child: content,
          );
        }

        return content;
      },
    );
  }
}

class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints, bool, bool) builder;
  
  const ResponsiveLayoutBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = ResponsiveUtils.shouldShowCompactLayout(context);
        final isWide = ResponsiveUtils.shouldShowWideLayout(context);
        
        return builder(context, constraints, isCompact, isWide);
      },
    );
  }
}

class OrientationLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, Orientation) builder;
  
  const OrientationLayoutBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return builder(context, orientation);
      },
    );
  }
}

class FlexibleSpacing extends StatelessWidget {
  final double baseHeight;
  final double minHeight;
  final double maxHeight;
  final bool flexible;

  const FlexibleSpacing({
    Key? key,
    required this.baseHeight,
    this.minHeight = 4.0,
    this.maxHeight = 100.0,
    this.flexible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!flexible) {
      return SizedBox(height: baseHeight);
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final maxAllowedHeight = math.min(maxHeight, availableHeight * 0.1).toDouble();
        final spacing = ResponsiveUtils.getIntelligentVerticalSpacing(
          context, 
          baseHeight,
        ).clamp(minHeight, maxAllowedHeight);
        
        return SizedBox(height: spacing);
      },
    );
  }
}

class FractionalWidthContainer extends StatelessWidget {
  final Widget child;
  final double widthFactor;
  final double minWidth;
  final double maxWidth;

  const FractionalWidthContainer({
    Key? key,
    required this.child,
    this.widthFactor = 0.9,
    this.minWidth = 300.0,
    this.maxWidth = 500.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final calculatedWidth = (availableWidth * widthFactor)
            .clamp(minWidth, math.min(maxWidth, availableWidth).toDouble());
        
        return Container(
          width: calculatedWidth,
          child: child,
        );
      },
    );
  }
}

class ExpandedSection extends StatelessWidget {
  final Widget child;
  final int flex;
  final bool enabled;

  const ExpandedSection({
    Key? key,
    required this.child,
    this.flex = 1,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    
    return Expanded(
      flex: flex,
      child: child,
    );
  }
}

class AspectRatioContainer extends StatelessWidget {
  final Widget child;
  final double aspectRatio;
  final bool adaptive;

  const AspectRatioContainer({
    Key? key,
    required this.child,
    this.aspectRatio = 16/9,
    this.adaptive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calculatedAspectRatio = adaptive 
        ? ResponsiveUtils.getAdaptiveAspectRatio(context)
        : aspectRatio;
        
    return AspectRatio(
      aspectRatio: calculatedAspectRatio,
      child: child,
    );
  }
}

class MediaQueryView extends StatelessWidget {
  final Widget Function(BuildContext, MediaQueryData) builder;

  const MediaQueryView({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return builder(context, mediaQuery);
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = crossAxisCount ?? 
            ResponsiveUtils.getIntelligentGridCount(context);
        
        return GridView.count(
          crossAxisCount: count,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}


// ✅ WIDGETS DE TEXTO RESPONSIVOS COMPATIBLES
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fontFamily;
  final FontStyle? fontStyle;

  const ResponsiveText(
    this.text, {
    Key? key,
    this.baseFontSize = 14,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontFamily = 'Poppins',
    this.fontStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, baseFontSize),
        fontWeight: fontWeight,
        color: color,
        fontFamily: fontFamily,
        fontStyle: fontStyle,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// ✅ WIDGETS COMPATIBLES CON VERSIÓN ANTERIOR
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool applyHorizontalPadding;
  final bool centerContent;
  final double? maxWidth;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.applyHorizontalPadding = true,
    this.centerContent = true,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: maxWidth ?? ResponsiveUtils.getMaxContentWidth(context),
      padding: padding ??
          (applyHorizontalPadding
              ? EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getHorizontalPadding(context),
                )
              : EdgeInsets.zero),
      child: child,
    );

    if (centerContent) {
      return Center(child: content);
    }

    return content;
  }
}

class ResponsiveSpacing extends StatelessWidget {
  final double baseHeight;

  const ResponsiveSpacing(this.baseHeight, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ResponsiveUtils.getVerticalSpacing(context, baseHeight),
    );
  }
}

class ResponsiveHorizontalSpacing extends StatelessWidget {
  final double baseWidth;

  const ResponsiveHorizontalSpacing(this.baseWidth, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ResponsiveUtils.getHorizontalSpacing(context, baseWidth),
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  
  const ResponsiveSafeArea({
    Key? key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

class ResponsiveDebug extends StatelessWidget {
  final Widget child;
  
  const ResponsiveDebug({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    assert(() {
      ResponsiveUtils.debugResponsiveInfo(context);
      return true;
    }());
    
    return child;
  }
}