// lib/presentation/patient/bloc/home_content_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/emotion/emotion_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/emotion_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_state.dart';

class HomeContentCubit extends Cubit<HomeContentState> {
  final EmotionBloc emotionBloc;
  final String patientId;

  HomeContentCubit({
    required this.emotionBloc,
    required this.patientId,
  }) : super(HomeContentState.initial());

  /// Selecciona un sentimiento y lo guarda automáticamente
  void selectFeeling(Feeling feeling) {
    print('🎯 Sentimiento seleccionado: $feeling');
    
    // Actualizar el estado local
    emit(state.copyWith(selectedFeeling: feeling));
    
    // Guardar automáticamente
    _saveEmotion(feeling);
  }

  /// Guarda la emoción seleccionada en el backend
  void _saveEmotion(Feeling feeling) {
    print('💾 Guardando emoción automáticamente...');
    
    final emotion = Emotion(
      id: '', // El ID se genera en el backend
      patientId: patientId,
      feeling: feeling,
      date: DateTime.now(),
      intensity: _getIntensityFromFeeling(feeling),
      note: null, // Sin nota inicial
      metadata: {}, // Metadatos vacíos
    );

    // Disparar el evento de guardado
    emotionBloc.add(SaveEmotion(emotion: emotion));
  }

  /// Convierte el sentimiento en intensidad numérica (1-10)
  int _getIntensityFromFeeling(Feeling feeling) {
    switch (feeling) {
      case Feeling.terrible:
        return 1;
      case Feeling.bad:
        return 3;
      case Feeling.neutral:
        return 5;
      case Feeling.good:
        return 7;
      case Feeling.great:
        return 9;
      default:
        return 5;
    }
  }

  /// Carga la emoción del día actual
  void loadTodayEmotion() {
    print('📥 Cargando emoción del día...');
    emotionBloc.add(LoadTodayEmotion(patientId));
  }

  /// Limpia el sentimiento seleccionado (opcional, para resetear UI)
  void clearFeeling() {
    emit(state.copyWith(selectedFeeling: null));
  }
}