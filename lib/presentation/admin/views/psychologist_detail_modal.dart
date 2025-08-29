import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/presentation/admin/bloc/psychologist_bloc.dart';
import 'package:provider/provider.dart';

class DetallePsicologoModal extends StatelessWidget {
  final Map<String, dynamic> psicologo;

  const DetallePsicologoModal({required this.psicologo, super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = const TextStyle(fontWeight: FontWeight.bold);

    // Lógica para manejar el campo de educación de forma robusta
    final educationData = psicologo["education"];
    String institutionName = "No especificada";

    if (educationData is List && educationData.isNotEmpty) {
      final firstElement = educationData[0];
      if (firstElement is Map<String, dynamic> && firstElement.containsKey("institution")) {
        institutionName = firstElement["institution"]?.toString() ?? "No especificada";
      } else if (firstElement is String) {
        institutionName = firstElement;
      }
    }
    
    return AlertDialog(
      title: Text(psicologo["fullName"] ?? "Sin nombre"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Especialidad:", style: titleStyle),
            Text(psicologo["specialty"] ?? "No especificada"),
            const SizedBox(height: 8),

            Text("Cédula profesional:", style: titleStyle),
            Text(psicologo["professionalLicense"] ?? "No registrada"),
            const SizedBox(height: 8),

            Text("Educación:", style: titleStyle),
            Text(institutionName), // Usamos la variable segura
            const SizedBox(height: 8),

            Text("Años de experiencia:", style: titleStyle),
            Text(psicologo["yearsExperience"]?.toString() ?? "No especificado"),
            const SizedBox(height: 8),

            Text("Estado:", style: titleStyle),
            Text(psicologo["status"] ?? "Desconocido"),
            const SizedBox(height: 8),

            const Text("Descripción:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(psicologo["description"] ?? "Sin descripción"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            context.read<PsychologistBloc>().add(UpdatePsychologistStatus(
                  psychologistId: psicologo['id'],
                  status: 'Activo',
                  adminNotes: 'Cédula validada correctamente',
                ));
            Navigator.pop(context);
          },
          child: const Text("Validar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            context.read<PsychologistBloc>().add(UpdatePsychologistStatus(
                  psychologistId: psicologo['id'],
                  status: 'Rechazado',
                  adminNotes: 'Cédula no válida',
                ));
            Navigator.pop(context);
          },
          child: const Text("Rechazar"),
        ),
      ],
    );
  }
}