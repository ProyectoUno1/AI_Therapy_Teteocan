import 'package:flutter/material.dart';

class DetallePsicologoModal extends StatelessWidget {
  final Map<String, dynamic> psicologo;

  const DetallePsicologoModal({required this.psicologo, super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = const TextStyle(fontWeight: FontWeight.bold);

    print("Datos recibidos en modal: $psicologo");

    return AlertDialog(
      title: Text(psicologo["nombre"] ?? "Sin nombre"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Especialidad:", style: titleStyle),
Text(psicologo["specialty"] ?? "No especificada"),

Text("Registro:", style: titleStyle),
Text(psicologo["registro"] ?? "No disponible"),

Text("Cédula profesional:", style: titleStyle),
Text(psicologo["cedula"] ?? "No registrada"),

Text("Universidad:", style: titleStyle),
Text(psicologo["universidad"] ?? "No especificada"),

            const SizedBox(height: 8),
            const Text(
              "Descripción:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(psicologo["descripcion"] ?? "Sin descripción"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
        ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green, // o el color que quieras
    foregroundColor: Colors.white, // texto blanco que resalte
  ),
  onPressed: () {},
  child: const Text("Validar"),
),
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white, // texto blanco que resalte
  ),
  onPressed: () {},
  child: const Text("Rechazar"),
),

      ],
    );
  }
}
