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

  Future<String> placeOrder(Order order) async {
    final doc = await _orders.add(order.toMap());
    return doc.id;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) {
    return _orders.doc(orderId).update({'status': status.name});
  }
}