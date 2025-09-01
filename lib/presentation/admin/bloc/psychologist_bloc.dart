import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_therapy_teteocan/data/repositories/psychologist_repository.dart';
part 'psychologist_event.dart';
part 'psychologist_state.dart';

class PsychologistBloc extends Bloc<PsychologistEvent, PsychologistState> {
  final PsychologistRepository repository;
  StreamSubscription? _psychologistsSubscription;

  PsychologistBloc({required this.repository}) : super(PsychologistInitial()) {
    on<LoadPsychologists>(_onLoadPsychologists);
    on<UpdatePsychologistStatus>(_onUpdatePsychologistStatus);
    on<PsychologistsUpdated>(_onPsychologistsUpdated);
  }

  void _onLoadPsychologists(LoadPsychologists event, Emitter<PsychologistState> emit) {
    _psychologistsSubscription?.cancel();
    _psychologistsSubscription = repository.getPsychologistsStream().listen(
      (psychologists) {
        add(PsychologistsUpdated(psychologists: psychologists));
      },
      onError: (error) {
        emit(PsychologistError(message: error.toString()));
      },
    );
  }

  void _onPsychologistsUpdated(PsychologistsUpdated event, Emitter<PsychologistState> emit) {
    emit(PsychologistsLoaded(psychologists: event.psychologists));
  }

  Future<void> _onUpdatePsychologistStatus(
    UpdatePsychologistStatus event,
    Emitter<PsychologistState> emit,
  ) async {
    try {
      await repository.updatePsychologistStatus(
        event.psychologistId,
        event.status,
        event.adminNotes ?? '',
      );
    } catch (error) {
      emit(PsychologistError(message: error.toString()));
    }
  }

  @override
  Future<void> close() {
    _psychologistsSubscription?.cancel();
    return super.close();
  }
}