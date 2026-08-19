import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/orders_repository.dart';

final ordersRepositoryProvider =
Provider<OrdersRepository>((ref) => OrdersRepository());

/// Live order history for the signed-in buyer. Empty when signed out.
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(ordersRepositoryProvider).watchOrders(user.uid);
});

class OrdersActions extends Notifier<void> {
  @override
  void build() {}

  Future<String> placeOrder(Order order) {
    return ref.read(ordersRepositoryProvider).placeOrder(order);
  }

  Future<void> updateStatus(String orderId, OrderStatus status) {
    return ref.read(ordersRepositoryProvider).updateStatus(orderId, status);
  }
}

final ordersActionsProvider =
NotifierProvider<OrdersActions, void>(OrdersActions.new);