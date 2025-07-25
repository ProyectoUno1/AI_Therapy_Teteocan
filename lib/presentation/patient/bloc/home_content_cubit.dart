// lib/presentation/patient/bloc/home_content_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/data/models/feeling_model.dart';
import 'package:ai_therapy_teteocan/presentation/patient/bloc/home_content_state.dart';

class HomeContentCubit extends Cubit<HomeContentState> {
  HomeContentCubit() : super(const HomeContentState(selectedFeeling: null)); 

  void selectFeeling(Feeling feeling) {
    emit(state.copyWith(selectedFeeling: feeling));
    
  }
}