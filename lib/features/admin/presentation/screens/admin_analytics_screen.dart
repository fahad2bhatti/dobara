import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';
import '../../domain/analytics_provider.dart';

/// Admin-only — Phase 2 of the Analytics feature: core stats cards
/// (total revenue, items sold, sales, average order value) plus an
/// order-status breakdown. Daily/monthly charts, top performers,
/// customer insights, and the monthly summary land in later phases.
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenue = ref.watch(totalRevenueProvider);
    final itemsSold = ref.watch(totalItemsSoldProvider);
    final salesCount = ref.watch(totalSalesCountProvider);
    final ordersCount = ref.watch(totalOrdersCountProvider);
    final avgOrderValue = ref.watch(averageOrderValueProvider);
    final statusBreakdown = ref.watch(orderStatusBreakdownProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Overview'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    label: 'Total Revenue',
                    value: 'Rs ${_formatMoney(revenue)}',
                    icon: Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Items Sold',
                    value: '$itemsSold',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Total Sales',
                    value: '$salesCount',
                    icon: Icons.check_circle_outline,
                    color: AppColors.successText,
                  ),
                  _StatCard(
                    label: 'Avg Order Value',
                    value: 'Rs ${_formatMoney(avgOrderValue)}',
                    icon: Icons.trending_up,
                    color: const Color(0xFF0B3A6E),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '$ordersCount total orders placed (including pending & cancelled)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Order Status Breakdown'),
              const SizedBox(height: 10),
              _StatusBreakdownCard(
                breakdown: statusBreakdown,
                total: ordersCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(icon, size: 18, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Simple horizontal-bar breakdown, one row per OrderStatus, showing
/// count + share of total orders. Every status shows even at zero, so
/// the shape of the list never jumps around as data comes in.
class _StatusBreakdownCard extends StatelessWidget {
  final Map<OrderStatus, int> breakdown;
  final int total;

  const _StatusBreakdownCard({required this.breakdown, required this.total});

  static const Map<OrderStatus, Color> _statusColors = {
    OrderStatus.placed: Color(0xFF9A9490),
    OrderStatus.confirmed: Color(0xFF1C62C4),
    OrderStatus.packed: Color(0xFFD4860A),
    OrderStatus.shipped: Color(0xFFC4704F),
    OrderStatus.outForDelivery: Color(0xFF6B3E00),
    OrderStatus.delivered: AppColors.successText,
    OrderStatus.cancelled: AppColors.errorText,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: total == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No orders placed yet.',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            )
          : Column(
              children: OrderStatus.values.map((status) {
                final count = breakdown[status] ?? 0;
                final fraction = total == 0 ? 0.0 : count / total;
                final color = _statusColors[status] ?? AppColors.textTertiary;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              status.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '$count (${(fraction * 100).round()}%)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          backgroundColor: AppColors.muted,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// PKR values shown with thousand separators (e.g. 125,400) — no
/// decimals since Product/Order store whole rupees.
String _formatMoney(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final posFromEnd = s.length - i;
    buf.write(s[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
