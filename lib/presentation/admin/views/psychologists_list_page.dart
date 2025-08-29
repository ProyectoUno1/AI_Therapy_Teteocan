import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/psychologist_bloc.dart';
import '../views/psychologist_detail_modal.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
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
    return BlocConsumer<PsychologistBloc, PsychologistState>(
      listener: (context, state) {
        if (state is PsychologistError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is PsychologistInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<PsychologistBloc>().add(LoadPsychologists());
          });
        }
        
        List<Map<String, dynamic>> psicologos = [];
        
        if (state is PsychologistsLoaded) {
          psicologos = state.psychologists;
        }

        final filteredPsicologos = psicologos.where((p) {
          final matchesSearch = p["fullName"]?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false;
          final matchesEstado = selectedEstado == null || p["status"] == selectedEstado;
          return matchesSearch && matchesEstado;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text("Panel de Administrador")),
          body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Buscar psicólogo...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: selectedEstado,
                        hint: const Text("Filtrar por estado"),
                        onChanged: (value) => setState(() => selectedEstado = value),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 47, 119, 102),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Agregar", style: TextStyle(color: Colors.white)), // <-- Cambio aquí
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: state is PsychologistLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: filteredPsicologos.length,
                          itemBuilder: (context, index) {
                            final psicologo = filteredPsicologos[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(psicologo["photoUrl"] ?? "https://i.pravatar.cc/150?img=1"),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                psicologo["fullName"] ?? "Sin nombre",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                                      color: _getStatusColor(psicologo["status"] ?? ""),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      psicologo["status"] ?? "Desconocido",
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      "Cédula: ${psicologo["professionalLicense"] ?? "No disponible"}",
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
                                          showDialog(
                                            context: context,
                                            builder: (_) => BlocProvider.value(
                                              value: context.read<PsychologistBloc>(),
                                              child: DetallePsicologoModal(psicologo: psicologo),
                                            ),
                                          );
                                        },
                                        child: const Text("Ver detalles", style: TextStyle(color: Colors.white)),
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
      },
    );
  }
}