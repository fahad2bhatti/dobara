import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/models/order_model.dart';

class OrdersRepository {
  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

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

  /// Places an order via the `placeOrder` Cloud Function instead of
  /// writing to Firestore directly. Only (listingId, quantity) + the
  /// delivery details are sent — price, name, image, and seller are all
  /// looked up server-side from the real listing docs, so nothing here
  /// can be tampered with client-side. `firestore.rules` backs this up
  /// by denying direct client `create`s on /orders.
  Future<String> placeOrder({
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String phone,
    required String address,
    required String city,
  }) async {
    final callable = _functions.httpsCallable('placeOrder');
    final result = await callable.call<Map<String, dynamic>>({
      'items': items,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'city': city,
    });
    return result.data['orderId'] as String;
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