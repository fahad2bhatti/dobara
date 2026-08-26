import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';
import '../../../orders/domain/orders_provider.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Orders')),
      body: SafeArea(
        child: ordersAsync.when(
          data: (orders) => orders.isEmpty
              ? const Center(child: Text('No orders yet.'))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _orderTile(context, orders[i]),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load orders: $e')),
        ),
      ),
    );
  }

  Widget _orderTile(BuildContext context, Order order) {
    final shortId = order.id.length >= 6
        ? order.id.substring(order.id.length - 6)
        : order.id;

    return GestureDetector(
      onTap: () => context.push('/admin/orders/update', extra: order),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#$shortId',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      _statusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(order.customerName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '${order.items.length} item${order.items.length == 1 ? '' : 's'} · Rs. ${_formatPrice(order.total)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                  if (order.trackingNumber != null) ...[
                    const SizedBox(height: 2),
                    Text('Tracking: ${order.trackingNumber}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.neutral200),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    final isCancelled = status == OrderStatus.cancelled;
    final isDelivered = status == OrderStatus.delivered;
    final bg = isCancelled
        ? AppColors.errorBg
        : isDelivered
        ? AppColors.successBg
        : AppColors.muted;
    final fg = isCancelled
        ? AppColors.errorText
        : isDelivered
        ? AppColors.successText
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
