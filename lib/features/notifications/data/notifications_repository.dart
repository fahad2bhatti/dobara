import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/notification_model.dart';

/// Firestore CRUD for a user's notification feed at
/// notifications/{uid}/items/{itemId}.
class NotificationsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection('notifications').doc(uid).collection('items');

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => AppNotification.fromDoc(d)).toList());
  }

  /// Called by the admin flow when an order's status changes — writes
  /// straight into the *buyer's* subcollection (allowed by rules for
  /// admins), not the caller's own.
  Future<void> notify(String buyerUid, AppNotification notification) {
    return _items(buyerUid).add(notification.toMap());
  }

  Future<void> markRead(String uid, String notificationId) {
    return _items(uid).doc(notificationId).update({'read': true});
  }

  Future<void> markAllRead(String uid) async {
    final snap = await _items(uid).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
