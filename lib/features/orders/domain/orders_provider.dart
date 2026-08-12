import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order_model.dart';

/// In-memory order history for this session. Newest first.
/// TODO Phase 11 (post-auth Firestore pass): persist to Firestore
/// under orders/{orderId}, scoped to the real signed-in user.
class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => [];

  void addOrder(Order order) {
    state = [order, ...state];
  }

  void updateStatus(String orderId, OrderStatus status) {
    state = [
      for (final o in state)
        if (o.id == orderId) o.copyWith(status: status) else o,
    ];
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);