import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateProfile(String uid, {required String name, required String phone}) {
    return _db.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
    });
  }

  Future<void> updateNotificationPrefs(
      String uid, {
        required bool notifyOrderUpdates,
        required bool notifyPromotions,
      }) {
    return _db.collection('users').doc(uid).update({
      'notifyOrderUpdates': notifyOrderUpdates,
      'notifyPromotions': notifyPromotions,
    });
  }
}
