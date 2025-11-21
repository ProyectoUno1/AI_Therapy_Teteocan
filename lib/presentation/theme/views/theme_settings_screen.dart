// lib/presentation/theme/views/theme_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_state.dart';

// Clase helper para responsive breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static double getContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktop) return desktop * 0.6;
    if (width >= tablet) return tablet * 0.8;
    return width;
  }
}

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Tema'),
        elevation: 0,
      ),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return OrientationBuilder(
                builder: (context, orientation) {
                  final isMobile = ResponsiveBreakpoints.isMobile(context);
                  final isTablet = ResponsiveBreakpoints.isTablet(context);
                  final isDesktop = ResponsiveBreakpoints.isDesktop(context);
                  final isLandscape = orientation == Orientation.landscape;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.getContentWidth(context),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16.0 : (isTablet ? 24.0 : 32.0),
                          vertical: isMobile ? 16.0 : 24.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Cambiado a min
                          children: [
                            // Título de la sección
                            _buildHeader(context, isMobile, isTablet),
                            
                            SizedBox(height: isMobile ? 24 : 32),

                            // Lista de opciones de tema - CORREGIDO
                            _buildThemeOptions(context, state, isMobile, isTablet, isDesktop, isLandscape),

                            SizedBox(height: isMobile ? 32 : 40),

                            // Información adicional
                            _buildInfoCard(context, isMobile, isTablet, isDesktop),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isTablet) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Apariencia',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 24 : (isTablet ? 28 : 32),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Text(
          'Selecciona el tema que prefieras para la aplicación',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOptions(
    BuildContext context,
    ThemeState state,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool isLandscape,
  ) {
    // Usar grid layout solo en tablets/desktop en landscape o desktop en portrait
    final useGridLayout = isDesktop || (isTablet && isLandscape);
    
    if (useGridLayout) {
      return _buildGridLayout(context, state, isMobile, isTablet, isDesktop, isLandscape);
    } else {
      return _buildListLayout(context, state, isMobile);
    }
  }

  Widget _buildGridLayout(
    BuildContext context,
    ThemeState state,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool isLandscape,
  ) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(width, isLandscape);
    final childAspectRatio = _getChildAspectRatio(width, isLandscape);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: ThemeOption.values.length,
      itemBuilder: (context, index) {
        final themeOption = ThemeOption.values[index];
        return _ThemeOptionTile(
          themeOption: themeOption,
          isSelected: state.selectedTheme == themeOption,
          onTap: () {
            context.read<ThemeCubit>().changeTheme(themeOption);
          },
          isGridLayout: true,
          isMobile: isMobile,
          isTablet: isTablet,
          isLandscape: isLandscape,
        );
      },
    );
  }

  int _getCrossAxisCount(double width, bool isLandscape) {
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _getChildAspectRatio(double width, bool isLandscape) {
    if (isLandscape) {
      return width > 900 ? 1.8 : 2.0;
    }
    return width > 900 ? 1.3 : (width > 600 ? 1.5 : 1.8);
  }

  Widget _buildListLayout(BuildContext context, ThemeState state, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Cambiado a min
      children: ThemeOption.values.map((themeOption) {
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          child: _ThemeOptionTile(
            themeOption: themeOption,
            isSelected: state.selectedTheme == themeOption,
            onTap: () {
              context.read<ThemeCubit>().changeTheme(themeOption);
            },
            isGridLayout: false,
            isMobile: isMobile,
            isTablet: false,
            isLandscape: false,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : (isTablet ? 20.0 : 24.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Cambiado a min
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: isMobile ? 24 : 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Cambiado a min
                    children: [
                      Text(
                        'Información',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 16 : 18,
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        'El tema automático se ajusta según la configuración de tu dispositivo. Los cambios se aplican inmediatamente sin necesidad de reiniciar la aplicación.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 13 : 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final ThemeOption themeOption;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isGridLayout;
  final bool isMobile;
  final bool isTablet;
  final bool isLandscape;

  const _ThemeOptionTile({
    required this.themeOption,
    required this.isSelected,
    required this.onTap,
    required this.isGridLayout,
    required this.isMobile,
    required this.isTablet,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isGridLayout) {
      return Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 16 : 20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Cambiado a min
              children: [
                // Ícono
                Container(
                  width: isLandscape ? 48 : 60,
                  height: isLandscape ? 48 : 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    themeOption.icon,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    size: isLandscape ? 24 : 28,
                  ),
                ),
                
                SizedBox(height: isLandscape ? 8 : 12),
                
                // Título
                Text(
                  themeOption.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isLandscape ? 14 : 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: isLandscape ? 4 : 6),
                
                // Descripción - CAMBIADO: Usar Flexible en lugar de Expanded
                Flexible(
                  child: Text(
                    _getThemeDescription(themeOption),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isLandscape ? 11 : 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: isLandscape ? 20 : 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // List layout (para móviles en portrait)
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 12,
        ),
        leading: Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            themeOption.icon,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            size: isMobile ? 24 : 28,
          ),
        ),
        title: Text(
          themeOption.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isMobile ? 16 : 17,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _getThemeDescription(themeOption),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: isMobile ? 13 : 14,
            ),
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: isMobile ? 24 : 28,
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getThemeDescription(ThemeOption option) {
    switch (option) {
      case ThemeOption.light:
        return 'Interfaz clara con colores brillantes';
      case ThemeOption.dark:
        return 'Interfaz oscura que reduce el cansancio visual';
      case ThemeOption.system:
        return 'Se ajusta automáticamente según tu dispositivo';
    }
  }
}