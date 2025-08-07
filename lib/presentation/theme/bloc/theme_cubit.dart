// lib/presentation/theme/bloc/theme_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/theme/bloc/theme_state.dart';
import 'package:ai_therapy_teteocan/core/services/theme_service.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeService _themeService;

  ThemeCubit(this._themeService) : super(const ThemeState()) {
    _loadSavedTheme();
  }

  /// Carga el tema guardado desde SharedPreferences
  Future<void> _loadSavedTheme() async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final savedTheme = await _themeService.getSavedTheme();
      emit(state.copyWith(
        selectedTheme: savedTheme,
        isLoading: false,
      ));
    } catch (e) {
      // Si hay error, usar tema por defecto (system)
      emit(state.copyWith(
        selectedTheme: ThemeOption.system,
        isLoading: false,
      ));
    }
  }

  /// Cambia el tema y lo guarda en SharedPreferences
  Future<void> changeTheme(ThemeOption newTheme) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      await _themeService.saveTheme(newTheme);
      emit(state.copyWith(
        selectedTheme: newTheme,
        isLoading: false,
      ));
    } catch (e) {
      // Si hay error al guardar, revertir al estado anterior
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Obtiene el tema actual
  ThemeOption get currentTheme => state.selectedTheme;
}