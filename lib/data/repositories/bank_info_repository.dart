import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_therapy_teteocan/data/models/bank_info_model.dart';
import 'package:ai_therapy_teteocan/data/models/payment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankInfoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BankInfoRepository();

  // Obtener información bancaria del psicólogo
  Future<BankInfoModel?> getBankInfo(String psychologistId) async {
    try {
      final doc = await _firestore
          .collection('bank_info')
          .doc(psychologistId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      return BankInfoModel.fromJson({
        ...data,
        'id': doc.id,
      });
    } catch (e) {
      print('Error obteniendo información bancaria: $e');
      throw Exception('Error al obtener información bancaria: $e');
    }
  }

  // Guardar nueva información bancaria
  Future<BankInfoModel> saveBankInfo(BankInfoModel bankInfo) async {
    try {
      await _firestore
          .collection('bank_info')
          .doc(bankInfo.psychologistId)
          .set(bankInfo.toJson());

      return bankInfo;
    } catch (e) {
      print('Error guardando información bancaria: $e');
      throw Exception('Error al guardar información bancaria: $e');
    }
  }

  // Actualizar información bancaria
  Future<BankInfoModel> updateBankInfo(BankInfoModel bankInfo) async {
    try {
      await _firestore
          .collection('bank_info')
          .doc(bankInfo.psychologistId)
          .update(bankInfo.toJson());

      return bankInfo;
    } catch (e) {
      print('Error actualizando información bancaria: $e');
      throw Exception('Error al actualizar información bancaria: $e');
    }
  }

  // Obtener historial de pagos desde la colección correcta
  Future<List<PaymentModel>> getPaymentHistory(
    String psychologistId, {
    String? status,
  }) async {
    try {
      print('🔍 Buscando pagos para psychologistId: $psychologistId');
      
      // Query base
      Query query = _firestore
          .collection('psychologist_payments')
          .where('psychologistId', isEqualTo: psychologistId);

      // Filtrar por estado si se especifica
      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      // Ordenar por fecha
      query = query.orderBy('paidAt', descending: true);

      final snapshot = await query.get();
      
      print('📦 Documentos encontrados: ${snapshot.docs.length}');

      final payments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('📄 Documento: ${doc.id}');
        print('   - Amount: ${data['amount']}');
        print('   - Status: ${data['status']}');
        
        return PaymentModel.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();

      print('✅ Pagos procesados: ${payments.length}');
      return payments;
    } catch (e) {
      print('❌ Error obteniendo historial de pagos: $e');
      throw Exception('Error al obtener historial de pagos: $e');
    }
  }

  // Eliminar información bancaria
  Future<void> deleteBankInfo(String psychologistId) async {
    try {
      await _firestore
          .collection('bank_info')
          .doc(psychologistId)
          .delete();
    } catch (e) {
      print('Error eliminando información bancaria: $e');
      throw Exception('Error al eliminar información bancaria: $e');
    }
  }

  // Obtener resumen de pagos
  Future<Map<String, double>> getPaymentSummary(String psychologistId) async {
    try {
      final payments = await getPaymentHistory(psychologistId);

      double totalEarned = 0;
      double pendingAmount = 0;

      for (var payment in payments) {
        if (payment.status == 'completed') {
          totalEarned += payment.amount;
        } else if (payment.status == 'pending') {
          pendingAmount += payment.amount;
        }
      }

      return {
        'totalEarned': totalEarned,
        'pendingAmount': pendingAmount,
      };
    } catch (e) {
      print('Error obteniendo resumen de pagos: $e');
      return {
        'totalEarned': 0.0,
        'pendingAmount': 0.0,
      };
    }
  }
}