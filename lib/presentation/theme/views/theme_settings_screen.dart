// lib/presentation/theme/views/theme_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_cubit.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_state.dart';

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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de la sección
                Text(
                  'Apariencia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona el tema que prefieras para la aplicación',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // Lista de opciones de tema
                ...ThemeOption.values.map((themeOption) {
                  return _ThemeOptionTile(
                    themeOption: themeOption,
                    isSelected: state.selectedTheme == themeOption,
                    onTap: () {
                      context.read<ThemeCubit>().changeTheme(themeOption);
                    },
                  );
                }),

                const SizedBox(height: 32),

                // Información adicional
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Información',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'El tema automático se ajusta según la configuración de tu dispositivo. Los cambios se aplican inmediatamente sin necesidad de reiniciar la aplicación.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final ThemeOption themeOption;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.themeOption,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            themeOption.icon,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          themeOption.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        subtitle: Text(_getThemeDescription(themeOption)),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
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