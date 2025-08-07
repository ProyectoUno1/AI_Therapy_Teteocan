// lib/presentation/theme/bloc/theme_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ThemeOption {
  light,
  dark,
  system,
}

extension ThemeOptionExtension on ThemeOption {
  String get displayName {
    switch (this) {
      case ThemeOption.light:
        return 'Tema claro';
      case ThemeOption.dark:
        return 'Tema oscuro';
      case ThemeOption.system:
        return 'Automático';
    }
  }

  IconData get icon {
    switch (this) {
      case ThemeOption.light:
        return Icons.light_mode;
      case ThemeOption.dark:
        return Icons.dark_mode;
      case ThemeOption.system:
        return Icons.brightness_auto;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }
}

class ThemeState extends Equatable {
  final ThemeOption selectedTheme;
  final bool isLoading;

  const ThemeState({
    this.selectedTheme = ThemeOption.system,
    this.isLoading = false,
  });

  @override
  List<Object> get props => [selectedTheme, isLoading];

  ThemeState copyWith({
    ThemeOption? selectedTheme,
    bool? isLoading,
  }) {
    return ThemeState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}