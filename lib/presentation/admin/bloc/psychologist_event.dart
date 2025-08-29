part of 'psychologist_bloc.dart';

abstract class PsychologistEvent extends Equatable {
  const PsychologistEvent();

  @override
  List<Object> get props => [];
}

class LoadPsychologists extends PsychologistEvent {}

class PsychologistsUpdated extends PsychologistEvent {
  final List<Map<String, dynamic>> psychologists;

  const PsychologistsUpdated({required this.psychologists});

  @override
  List<Object> get props => [psychologists];
}

class UpdatePsychologistStatus extends PsychologistEvent {
  final String psychologistId;
  final String status;
  final String? adminNotes;

  const UpdatePsychologistStatus({
    required this.psychologistId,
    required this.status,
    this.adminNotes,
  });

  @override
  List<Object> get props => [psychologistId, status,];
}