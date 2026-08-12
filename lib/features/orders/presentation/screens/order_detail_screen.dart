import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';

const List<OrderStatus> _kTrackableStatuses = [
  OrderStatus.placed,
  OrderStatus.confirmed,
  OrderStatus.shipped,
  OrderStatus.delivered,
];

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final currentIndex = isCancelled
        ? -1
        : _kTrackableStatuses.indexOf(order.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${order.id.substring(order.id.length - 6)}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status stepper ─────────────────────
              if (!isCancelled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: List.generate(_kTrackableStatuses.length, (i) {
                      final done = i <= currentIndex;
                      final isLast = i == _kTrackableStatuses.length - 1;
                      return Expanded(
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: done
                                        ? AppColors.primary
                                        : AppColors.muted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: done
                                      ? const Icon(Icons.check,
                                      size: 13, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _kTrackableStatuses[i].label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: done
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  margin:
                                  const EdgeInsets.only(bottom: 20),
                                  height: 2,
                                  color: i < currentIndex
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'This order was cancelled.',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.errorText),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Items ────────────────────────────────
              const Text('ITEMS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 10),
              ...order.items.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 64,
                        child: CachedNetworkImage(
                          imageUrl: p.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Sold by ${p.seller.name}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    Text('Rs. ${_formatPrice(p.price)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              )),
              const SizedBox(height: 10),

              // ── Delivery address ─────────────────────
              const Text('DELIVERY ADDRESS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customerName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(order.phone,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('${order.address}, ${order.city}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Payment summary ──────────────────────
              const Text('PAYMENT SUMMARY',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _row('Subtotal', 'Rs. ${_formatPrice(order.subtotal)}'),
                    const SizedBox(height: 4),
                    _row('Delivery', 'Rs. ${_formatPrice(order.deliveryFee)}'),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 8),
                    _row('Total', 'Rs. ${_formatPrice(order.total)}',
                        bold: true),
                    const SizedBox(height: 8),
                    _row('Payment Method', 'Cash on Delivery'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 14 : 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color:
                bold ? AppColors.textPrimary : AppColors.textTertiary)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: bold ? AppColors.primary : AppColors.textPrimary)),
      ],
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