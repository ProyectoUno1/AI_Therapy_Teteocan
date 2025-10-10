// lib/presentation/psychologist/views/patient_management_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/views/patient_management_screen.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_management_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/psychologist/bloc/patient_management_event.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_bloc.dart';
import 'package:ai_therapy_teteocan/presentation/auth/bloc/auth_state.dart';

class PatientManagementWrapper extends StatelessWidget {
  const PatientManagementWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final psychologistId = context.watch<AuthBloc>().state.psychologist?.uid ?? '';

    return BlocProvider<PatientManagementBloc>(
      create: (context) {
        final bloc = PatientManagementBloc();
        if (psychologistId.isNotEmpty) {
          bloc.add(LoadPatientsEvent(psychologistId: psychologistId));
        }
        return bloc;
      },
      child: PatientManagementScreen(), 
    );
  }
}