// lib/presentation/patient/bloc/emotion/emotion_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/emotion_model.dart';
import 'package:ai_therapy_teteocan/data/repositories/emotion_repository.dart';

part './emotion_event.dart';
part './emotion_state.dart';

class EmotionBloc extends Bloc<EmotionEvent, EmotionState> {
  final EmotionRepository emotionRepository;

  EmotionBloc({required this.emotionRepository}) : super(EmotionInitial()) {
    on<SaveEmotion>(_onSaveEmotion);
    on<LoadTodayEmotion>(_onLoadTodayEmotion);
    on<LoadPatientEmotions>(_onLoadPatientEmotions);
  }

  Future<void> _onSaveEmotion(SaveEmotion event, Emitter<EmotionState> emit) async {
    emit(EmotionSaving());
    try {
      await emotionRepository.saveEmotion(event.emotion);
      emit(EmotionSavedSuccessfully());
      
      // Recargar la emoción del día después de guardar
      add(LoadTodayEmotion(event.emotion.patientId));
    } catch (e) {
      emit(EmotionError('Error al guardar emoción: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTodayEmotion(LoadTodayEmotion event, Emitter<EmotionState> emit) async {
    emit(EmotionLoading());
    try {
      final todayEmotion = await emotionRepository.getTodayEmotion(event.patientId);
      emit(EmotionLoaded(todayEmotion: todayEmotion));
    } catch (e) {
      emit(EmotionError('Error al cargar emoción del día: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPatientEmotions(LoadPatientEmotions event, Emitter<EmotionState> emit) async {
    emit(EmotionLoading());
    try {
      final emotions = await emotionRepository.getPatientEmotions(event.patientId);
      emit(EmotionsHistoryLoaded(emotions: emotions));
    } catch (e) {
      emit(EmotionError('Error al cargar historial de emociones: ${e.toString()}'));
    }
  }
}