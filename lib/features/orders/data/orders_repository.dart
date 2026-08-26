import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../shared/models/order_model.dart';

class OrdersRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Live order history for this buyer, newest first.
  Stream<List<Order>> watchOrders(String buyerId) {
    return _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('placedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Order.fromDoc(doc)).toList());
  }

  /// All orders across all buyers, newest first — admin only (enforced
  /// by Firestore rules; a non-admin caller would get permission-denied
  /// on the first doc, not a filtered result).
  Stream<List<Order>> watchAllOrders() {
    return _orders
        .orderBy('placedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Order.fromDoc(doc)).toList());
  }

  Future<String> placeOrder(Order order) async {
    final doc = await _orders.add(order.toMap());
    return doc.id;
  }

  /// Admin status update — status is required, tracking/courier are
  /// optional (only meaningful once the order ships, but admin can set
  /// them earlier too, e.g. to pre-fill before marking Shipped).
  Future<void> updateStatus(
      String orderId,
      OrderStatus status, {
        String? trackingNumber,
        String? courierName,
      }) {
    final update = <String, dynamic>{
      'status': status.name,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (trackingNumber != null) update['trackingNumber'] = trackingNumber;
    if (courierName != null) update['courierName'] = courierName;
    return _orders.doc(orderId).update(update);
  }
}