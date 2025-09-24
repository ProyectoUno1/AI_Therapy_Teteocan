// lib/presentation/patient/bloc/emotion/emotion_event.dart
part of 'emotion_bloc.dart';

abstract class EmotionEvent extends Equatable {
  const EmotionEvent();

  @override
  List<Object> get props => [];
}

class SaveEmotion extends EmotionEvent {
  final Emotion emotion;

  const SaveEmotion({required this.emotion});

  @override
  List<Object> get props => [emotion];
}

class LoadTodayEmotion extends EmotionEvent {
  final String patientId;

  const LoadTodayEmotion(this.patientId);

  @override
  List<Object> get props => [patientId];
}

class LoadPatientEmotions extends EmotionEvent {
  final String patientId;

  const LoadPatientEmotions(this.patientId);

  @override
  List<Object> get props => [patientId];
}