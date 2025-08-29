import 'package:cloud_firestore/cloud_firestore.dart';

class PsychologistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getPsychologistsStream() {
    return _firestore
        .collection('psychologist_professional_info')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Future<void> updatePsychologistStatus(
    String psychologistId,
    String status,
    String adminNotes,
  ) async {
    await _firestore.collection('psychologist_professional_info').doc(psychologistId).update({
      'status': status,
      'adminNotes': adminNotes,
      'validatedAt': FieldValue.serverTimestamp(),
      'validatedBy': 'adminUserId',
    });
  }
}