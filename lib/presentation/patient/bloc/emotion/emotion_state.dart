// lib/presentation/patient/bloc/emotion/emotion_state.dart

part of 'emotion_bloc.dart';

abstract class EmotionState extends Equatable {
  const EmotionState();

  @override
  List<Object> get props => [];
}

class EmotionInitial extends EmotionState {}

class EmotionLoading extends EmotionState {}

class EmotionSaving extends EmotionState {}

class EmotionSavedSuccessfully extends EmotionState {}

class EmotionLoaded extends EmotionState {
  final Emotion? todayEmotion;

  const EmotionLoaded({this.todayEmotion});

  @override
  List<Object> get props => [todayEmotion ?? Object()];
}

class EmotionsHistoryLoaded extends EmotionState {
  final List<Emotion> emotions;

  const EmotionsHistoryLoaded({required this.emotions});

  @override
  List<Object> get props => [emotions];
}

class EmotionError extends EmotionState {
  final String message;

  const EmotionError(this.message);

  @override
  List<Object> get props => [message];
}