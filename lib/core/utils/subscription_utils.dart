// lib/core/utils/subscription_utils.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionUtils {
  static Stream<bool> getPremiumStatusStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['isPremium'] == true);
  }

  static Stream<int> getRemainingMessagesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('patients')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data() ?? {};
      if (data['isPremium'] == true) {
        return 99999; 
      }
      final used = data['messageCount'] ?? 0;
      return (5 - used).toInt(); // 5 mensajes gratis
    });
  }

  static Future<void> resetMessageCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .update({'messageCount': 0});
    }
  }
}