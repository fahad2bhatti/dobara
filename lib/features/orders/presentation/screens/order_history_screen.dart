import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/orders_provider.dart';

import 'package:go_router/go_router.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    // Admins see every order in the app (not just their own purchases);
    // tapping one opens the admin update screen instead of the buyer
    // read-only detail screen, so this doubles as a shortcut into order
    // management without going through the Admin Panel.
    final ordersAsync = ref.watch(
      isAdmin ? adminOrdersStreamProvider : ordersStreamProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isAdmin ? 'All Orders' : 'My Orders')),
      body: SafeArea(
        child: ordersAsync.when(
          data: (orders) => orders.isEmpty
              ? _buildEmpty(isAdmin)
              : _buildList(context, orders, isAdmin),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load orders: $e')),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isAdmin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 52, color: AppColors.textSecondary.withValues(alpha: 0.35)),
            const SizedBox(height: 10),
            Text(
              isAdmin ? 'No orders yet' : 'No orders yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAdmin
                  ? 'Orders placed by buyers will show up here.'
                  : 'Orders you place will show up here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<Order> orders, bool isAdmin) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final order = orders[i];
        return GestureDetector(
          onTap: () => isAdmin
              ? context.push('/admin/orders/update', extra: order)
              : context.push('/order-history/detail', extra: order),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    _statusChip(order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? '${order.customerName} · ${order.items.length} item${order.items.length > 1 ? 's' : ''} · '
                      '${_formatDate(order.placedAt)}'
                      : '${order.items.length} item${order.items.length > 1 ? 's' : ''} · '
                      '${_formatDate(order.placedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.items.map((p) => p.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rs. ${_formatPrice(order.total)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(OrderStatus status) {
    final colors = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return (AppColors.warningBg, AppColors.warningText);
      case OrderStatus.confirmed:
      case OrderStatus.packed:
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return (const Color(0xFFD9EEFF), const Color(0xFF0B3A6E));
      case OrderStatus.delivered:
        return (AppColors.successBg, AppColors.successText);
      case OrderStatus.cancelled:
        return (AppColors.errorBg, AppColors.errorText);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
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