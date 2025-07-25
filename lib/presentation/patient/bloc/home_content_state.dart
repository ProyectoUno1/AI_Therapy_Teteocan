// lib/presentation/patient/bloc/home_content_state.dart
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';

class HomeContentState extends Equatable {
  final Feeling? selectedFeeling; 

  const HomeContentState({this.selectedFeeling});

  @override
  List<Object?> get props => [selectedFeeling];

  HomeContentState copyWith({
    Feeling? selectedFeeling,
  }) {
    return HomeContentState(
      selectedFeeling: selectedFeeling ?? this.selectedFeeling,
    );
  }
}