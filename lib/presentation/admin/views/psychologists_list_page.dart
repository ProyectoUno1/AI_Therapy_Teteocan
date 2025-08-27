import 'package:flutter/material.dart';

import '../views/psychologist_detail_modal.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final List<Map<String, dynamic>> psicologos = [
    {
      "nombre": "Dr. Juan Pérez",
      "specialty": "Terapia cognitivo-conductual",
      "registro": "23 de marzo",
      "estado": "Activo",
      "photo": "https://i.pravatar.cc/150?img=1",
      "cedula": "1234567",
      "universidad": "UNAM",
      "descripcion": "Especialista en terapia para adultos con ansiedad y depresión."
    },
    {
      "nombre": "Dra. Laura Martínez",
      "specialty": "Psicología clínica",
      "registro": "12 de marzo",
      "estado": "Inactivo",
      "photo": "https://i.pravatar.cc/150?img=2",
      "cedula": "7654321",
      "universidad": "UAM",
      "descripcion": "Experiencia en psicología clínica con enfoque en adolescentes."
    },
    {
      "nombre": "Dra. Ana Sánchez",
      "specialty": "Psicoterapia",
      "registro": "08 de marzo",
      "estado": "Pendiente",
      "photo": "https://i.pravatar.cc/150?img=3",
      "cedula": "1122334",
      "universidad": "ITESM",
      "descripcion": "Psicoterapeuta enfocada en terapia de pareja y familiar."
    },
  ];

  String? selectedEstado;
  String searchQuery = "";

  Color _getStatusColor(String estado) {
    switch (estado) {
      case "Activo":
        return Colors.green[300]!;
      case "Inactivo":
        return Colors.grey[400]!;
      case "Pendiente":
        return Colors.orange[300]!;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPsicologos = psicologos.where((p) {
      final matchesSearch = p["nombre"]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final matchesEstado =
          selectedEstado == null || p["estado"] == selectedEstado;
      return matchesSearch && matchesEstado;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Panel de Administrador")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar psicólogo...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 10),

            // Filtro + Botón
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: selectedEstado,
                    hint: const Text("Filtrar por estado"),
                    onChanged: (value) {
                      setState(() {
                        selectedEstado = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                       DropdownMenuItem(value: null, child: Text("Todos")),
                      DropdownMenuItem(value: "Activo", child: Text("Activo")),
                      DropdownMenuItem(value: "Inactivo", child: Text("Inactivo")),
                      DropdownMenuItem(value: "Pendiente", child: Text("Pendiente")),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 47, 119, 102),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Agregar psicólogo",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de psicólogos
            Expanded(
              child: ListView.builder(
                itemCount: filteredPsicologos.length,
                itemBuilder: (context, index) {
                  final psicologo = filteredPsicologos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(psicologo["photo"] ?? ""),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      psicologo["nombre"] ?? "Sin nombre",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      psicologo["specialty"] ?? "No especificada",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(psicologo["estado"] ?? ""),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            psicologo["estado"] ?? "Desconocido",
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Registro: ${psicologo["registro"] ?? "No disponible"}",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 47, 119, 102),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {
                                print("Psicólogo seleccionado: $psicologo");
                                showDialog(
                                  context: context,
                                  builder: (_) => DetallePsicologoModal(psicologo: psicologo),
                                );
                              },
                              child: const Text(
                                "Ver detalles",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';

// import '../views/psychologist_detail_modal.dart'; 

// class AdminPanel extends StatelessWidget {
//   // Más adelante esta lista vendrá de Firebase
//   final List<Map<String, dynamic>> psicologos = [
//     {"nombre": "Dr. Juan Pérez", "specialty": "TCC", "registro": "23 de marzo", "professionalLicense": "1234567890", "email": "juan.perez@example.com", "phone": "000000000000", "address": "Calle 123, Ciudad, País", "description": "Experto en psicología clínica y terapéutica.", "education": "Licenciatura en Psicología Clínica, Universidad de la Ciudad", "experience": "10 años de experiencia en terapia clínica y psicología clínica.", "languages": "Español, Inglés", "certifications": "Certificado en Psicoterapia Clínica, Certificado en Terapia de Caso", "consultationFee": 150.00, "availability": "Lunes a Viernes, 9:00 AM - 5:00 PM", "consultationType": "Presencial", "consultationMode": "En línea", "consultationDuration": 60, "consultationLocation": "Centro de Terapia Psicologica", "consultationDays": "Lunes a Viernes", "consultationHours": "9:00 AM - 5:00 PM", "consultationFeeCurrency": "MXN"},
//     {"nombre": "Dra. Laura Martínez", "specialty": "Clínica", "registro": "12 de marzo", "professionalLicense": "876661234523", },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Panel de Administrador")),
//       body: ListView.builder(
//         itemCount: psicologos.length,
//         itemBuilder: (context, index) {
//           final psicologo = psicologos[index];
//           return Card(
//             margin: EdgeInsets.all(10),
//             child: ListTile(
//               title: Text(psicologo["nombre"]),
//               subtitle: Text(psicologo["specialty"]),
//               trailing: ElevatedButton(
//                 onPressed: () {
//                   showDialog(
//                     context: context,
//                     builder: (_) => DetallePsicologoModal(psicologo: psicologo),
//                   );
//                 },
//                 child: Text("Ver detalles"),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

