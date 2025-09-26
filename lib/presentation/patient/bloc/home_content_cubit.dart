// lib/presentation/patient/bloc/home_content_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/emotion/emotion_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/emotion_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_state.dart';

class HomeContentCubit extends Cubit<HomeContentState> {
  final EmotionBloc emotionBloc;
  final String patientId;

  HomeContentCubit({required this.emotionBloc, required this.patientId})
    : super(HomeContentState.initial());

  void selectFeeling(Feeling feeling) {
    emit(state.copyWith(selectedFeeling: feeling));

    // Guardar automáticamente cuando se selecciona un sentimiento
    _saveEmotion(feeling);
  }

  void _saveEmotion(Feeling feeling) {
    final emotion = Emotion(
      patientId: patientId,
      feeling: feeling,
      date: DateTime.now(),
      intensity: _getIntensityFromFeeling(feeling),
    );

    emotionBloc.add(SaveEmotion(emotion: emotion));
  }

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

  void loadTodayEmotion() {
    emotionBloc.add(LoadTodayEmotion(patientId));
  }
}
