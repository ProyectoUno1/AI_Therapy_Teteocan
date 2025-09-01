part of 'psychologist_bloc.dart';

abstract class PsychologistState extends Equatable {
  const PsychologistState();

  @override
  List<Object> get props => [];
}

class PsychologistInitial extends PsychologistState {}

class PsychologistLoading extends PsychologistState {}

class PsychologistsLoaded extends PsychologistState {
  final List<Map<String, dynamic>> psychologists;

  const PsychologistsLoaded({required this.psychologists});

  @override
  List<Object> get props => [psychologists];
}

class PsychologistError extends PsychologistState {
  final String message;

  const PsychologistError({required this.message});

  @override
  List<Object> get props => [message];
}