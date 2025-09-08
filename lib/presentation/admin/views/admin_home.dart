import 'package:flutter/material.dart';

import 'psychologists_list_page.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con saludo y foto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Buen día 👋",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Admin",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=11", // foto de admin
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Métricas
              const Text(
                "Métricas",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    _MetricRow("Citas programadas", "120"),
                    Divider(),
                    _MetricRow("Citas del día", "8"),
                    Divider(),
                    _MetricRow("Registros activos", "50"),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Solicitudes pendientes
              const Text(
                "Solicitudes pendientes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.teal),
                        SizedBox(width: 8),
                        Text("Pendientes"),
                      ],
                    ),
                    Text("5", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Psicólogos ingresados
              const Text(
                "Psicólogos ingresados",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Eduardo Bastias"),
                  Divider(),
                  Text("Gabriela Campo"),
                  Divider(),
                  Text("Daniela Soto"),
                ],
              ),
              const SizedBox(height: 25),

              // Botón para validar psicólogos
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanel()),
                  );
                },
                icon: const Icon(Icons.verified_user, color: Colors.white),
                label: const Text(
                  "Validar Psicólogos",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),

      // Menú inferior
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Pacientes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.psychology), label: "Psicólogos"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}

// Widget reutilizable para filas de métricas
class _MetricRow extends StatelessWidget {
  final String title;
  final String value;

  const _MetricRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}