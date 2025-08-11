// lib/presentation/psychologist/bloc/psychologist_info_state.dart

import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/models/psychologist_model.dart'; 

abstract class PsychologistInfoState extends Equatable {
  const PsychologistInfoState();

  @override
  List<Object?> get props => [];
}

class PsychologistInfoInitial extends PsychologistInfoState {}

class PsychologistInfoLoading extends PsychologistInfoState {}


class PsychologistInfoLoaded extends PsychologistInfoState {
  final PsychologistModel psychologist;

  const PsychologistInfoLoaded({required this.psychologist});

  @override
  List<Object?> get props => [psychologist];
}

class PsychologistInfoSaved extends PsychologistInfoState {}

class PsychologistInfoError extends PsychologistInfoState {
  final String message;

  const PsychologistInfoError({required this.message});

  @override
  List<Object?> get props => [message];
}