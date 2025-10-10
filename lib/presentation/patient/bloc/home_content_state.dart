// lib/presentation/patient/bloc/home_content_state.dart
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';

class HomeContentState {
  final Feeling selectedFeeling;
  final bool isLoading;
  final String? error;

  const HomeContentState({
    required this.selectedFeeling,
    required this.isLoading,
    this.error,
  });

  factory HomeContentState.initial() {
    return const HomeContentState(
      selectedFeeling: Feeling.neutral,
      isLoading: false,
    );
  }

  HomeContentState copyWith({
    Feeling? selectedFeeling,
    bool? isLoading,
    String? error,
  }) {
    return HomeContentState(
      selectedFeeling: selectedFeeling ?? this.selectedFeeling,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is HomeContentState &&
        other.selectedFeeling == selectedFeeling &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode => selectedFeeling.hashCode ^ isLoading.hashCode ^ error.hashCode;
}