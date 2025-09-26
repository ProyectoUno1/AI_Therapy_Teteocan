import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/patient_note.dart';

class PatientNotesScreen extends StatelessWidget {
  final String patientName = "Juan Pérez"; // Hardcoded patient name

  // Hardcoded list of notes
  final List<PatientNote> notes = [
    PatientNote(
      id: '1',
      patientId: '123',
      title: 'Primera Sesión',
      content:
          'El paciente muestra signos de ansiedad social. Se recomienda ejercicios de respiración y exposición gradual.',
      date: DateTime(2025, 9, 20),
    ),
    PatientNote(
      id: '2',
      patientId: '123',
      title: 'Seguimiento',
      content:
          'Mejora notable en situaciones sociales. Continuar con ejercicios de mindfulness.',
      date: DateTime(2025, 9, 23),
    ),
    PatientNote(
      id: '3',
      patientId: '123',
      title: 'Evaluación Mensual',
      content:
          'El paciente ha desarrollado mejores estrategias de afrontamiento. Se observa progreso significativo.',
      date: DateTime(2025, 9, 25),
    ),
  ];

  PatientNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notas - $patientName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Aquí iría la navegación a la pantalla de crear nota
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de agregar nota en desarrollo'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text(
                note.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(note.date),
                style: const TextStyle(color: Colors.grey),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.content, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Aquí iría la función de editar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Función de editar en desarrollo',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Editar'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Aquí iría la función de eliminar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Función de eliminar en desarrollo',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí iría la navegación a la pantalla de crear nota
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de agregar nota en desarrollo'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
