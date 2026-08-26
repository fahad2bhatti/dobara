import 'package:cloud_firestore/cloud_firestore.dart';

/// In-app notification — currently used for order status updates.
/// Stored per-user at notifications/{uid}/items/{id}. This is an
/// in-app feed, not a push notification: real push (FCM) needs a
/// server-side trigger (Cloud Functions), which requires the Blaze
/// plan that hit a billing error earlier on this project. This gives
/// the buyer a real, reliable "you have an update" signal without
/// depending on that.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? orderId;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.orderId,
    required this.createdAt,
    this.read = false,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'orderId': orderId,
    'createdAt': FieldValue.serverTimestamp(),
    'read': read,
  };

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return AppNotification(
      id: doc.id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      orderId: map['orderId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] ?? false,
    );
  }
}
