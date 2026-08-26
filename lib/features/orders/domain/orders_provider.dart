import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/notification_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../notifications/data/notifications_providers.dart';
import '../data/orders_repository.dart';

final ordersRepositoryProvider =
Provider<OrdersRepository>((ref) => OrdersRepository());

/// Live order history for the signed-in buyer. Empty when signed out.
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(ordersRepositoryProvider).watchOrders(user.uid);
});

/// All orders, across every buyer — for the admin orders screen only.
final adminOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).watchAllOrders();
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

  /// Admin-only: updates status (+ optional tracking/courier) and drops
  /// a notification into the buyer's feed in the same action, so the
  /// buyer always finds out about every update — this is what makes
  /// status changes feel real/"premium" rather than silent.
  Future<void> adminUpdateOrder(
      Order order,
      OrderStatus newStatus, {
        String? trackingNumber,
        String? courierName,
      }) async {
    await ref.read(ordersRepositoryProvider).updateStatus(
      order.id,
      newStatus,
      trackingNumber: trackingNumber,
      courierName: courierName,
    );

    final shortId = order.id.length >= 6
        ? order.id.substring(order.id.length - 6)
        : order.id;
    var body = 'Your order #$shortId is now ${newStatus.label}.';
    final courier = courierName ?? order.courierName;
    final tracking = trackingNumber ?? order.trackingNumber;
    if (courier != null && tracking != null) {
      body += ' Tracking: $tracking via $courier.';
    } else if (tracking != null) {
      body += ' Tracking: $tracking.';
    }

    await ref.read(notificationsRepositoryProvider).notify(
      order.buyerId,
      AppNotification(
        id: '',
        title: 'Order update',
        body: body,
        orderId: order.id,
        createdAt: DateTime.now(),
      ),
    );
  }
}

final ordersActionsProvider =
NotifierProvider<OrdersActions, void>(OrdersActions.new);