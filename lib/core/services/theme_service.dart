// lib/core/services/theme_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_state.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';

  /// Guarda el tema seleccionado en SharedPreferences
  Future<void> saveTheme(ThemeOption theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }

  /// Obtiene el tema guardado desde SharedPreferences
  Future<ThemeOption> getSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeName = prefs.getString(_themeKey);
    
    if (savedThemeName == null) {
      return ThemeOption.system; // Tema por defecto
    }

    // Convierte el string guardado de vuelta a ThemeOption
    switch (savedThemeName) {
      case 'light':
        return ThemeOption.light;
      case 'dark':
        return ThemeOption.dark;
      case 'system':
        return ThemeOption.system;
      default:
        return ThemeOption.system; // Fallback por seguridad
    }
  }

  /// Limpia la configuración de tema guardada
  Future<void> clearSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}