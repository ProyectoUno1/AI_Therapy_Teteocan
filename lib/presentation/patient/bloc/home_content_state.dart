// lib/presentation/patient/bloc/home_content_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';

class HomeContentState extends Equatable {
  final Feeling? selectedFeeling;
  final bool isLoading;

  const HomeContentState({
    this.selectedFeeling,
    this.isLoading = false,
  });

  /// Estado inicial
  factory HomeContentState.initial() {
    return const HomeContentState(
      selectedFeeling: null,
      isLoading: false,
    );
  }

  /// Copia el estado con nuevos valores
  HomeContentState copyWith({
    Feeling? selectedFeeling,
    bool? isLoading,
  }) {
    return HomeContentState(
      selectedFeeling: selectedFeeling ?? this.selectedFeeling,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [selectedFeeling, isLoading];

  @override
  String toString() => 'HomeContentState(selectedFeeling: $selectedFeeling, isLoading: $isLoading)';
}