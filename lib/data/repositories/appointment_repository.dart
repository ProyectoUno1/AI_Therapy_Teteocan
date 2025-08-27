// lib/data/repositories/appointment_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/appointment_model.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore;

  AppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    // 1. Accede a la colección 'appointments' en Firestore.
    // 2. Filtra los documentos donde el campo 'patientId' sea igual al ID proporcionado.
    // 3. Usa .snapshots() para obtener un Stream de QuerySnapshot.
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .orderBy('scheduledDateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      // 4. Mapea cada documento (QueryDocumentSnapshot) a un objeto AppointmentModel.
      return snapshot.docs.map((doc) {
        return AppointmentModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}