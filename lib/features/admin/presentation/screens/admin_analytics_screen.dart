import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/order_model.dart';
import '../../domain/analytics_provider.dart';

/// Admin-only Analytics screen, built out phase by phase:
/// Phase 2 — core stats cards + order-status breakdown.
/// Phase 3 — daily (14-day) and monthly (6-month) sales charts.
/// Top performers, customer insights, and the monthly summary land in
/// later phases.
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
              const SizedBox(height: 24),
              const _SectionLabel('Daily Sales'),
              const SizedBox(height: 10),
              _DailySalesChart(points: ref.watch(dailySalesHistoryProvider)),
              const SizedBox(height: 24),
              const _SectionLabel('Monthly Sales — Last 6 Months'),
              const SizedBox(height: 10),
              _MonthlySalesChart(points: ref.watch(monthlySalesProvider)),
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

/// Bar chart over the store's full daily sales history, oldest to
/// newest. A day with no delivered orders still gets a flat/grey bar
/// rather than being skipped — the gap itself is the point ("which
/// days had no sales"). Horizontally scrollable so admin can explore
/// any past day, and the calendar button jumps straight to one.
class _DailySalesChart extends StatefulWidget {
  final List<DailySalesPoint> points; // full history, ascending
  const _DailySalesChart({required this.points});

  @override
  State<_DailySalesChart> createState() => _DailySalesChartState();
}

class _DailySalesChartState extends State<_DailySalesChart> {
  static const double _barSlotWidth = 30;
  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late final ScrollController _scrollController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Open scrolled to the most recent days, same as the old fixed
    // 14-day view used to show by default.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final points = widget.points;
    if (points.isEmpty) return;
    final picked = await showDatePicker(
      context: context,
      firstDate: points.first.day,
      lastDate: points.last.day,
      initialDate: points.last.day,
      helpText: 'View sales for a day',
    );
    if (picked == null || !mounted) return;

    final targetDay = DateTime(picked.year, picked.month, picked.day);
    final idx = points.indexWhere((p) => p.day == targetDay);
    if (idx == -1) return; // outside recorded history — shouldn't happen given firstDate/lastDate bounds

    setState(() => _selectedIndex = idx);

    if (_scrollController.hasClients) {
      // Centre the selected bar roughly in the visible strip rather
      // than pinning it to the very edge.
      final target = (idx * _barSlotWidth) - 120;
      _scrollController.animateTo(
        target.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final maxRevenue = points.fold<int>(0, (m, p) => p.revenue > m ? p.revenue : m);
    // A flat zero chart (no sales at all yet) still needs a non-zero
    // axis max, or fl_chart renders a degenerate 0..0 chart.
    final chartMax = maxRevenue == 0 ? 100 : (maxRevenue * 1.2).ceil();
    final chartWidth = points.length * _barSlotWidth;
    final selected = _selectedIndex != null ? points[_selectedIndex!] : null;
    // Cap the number of bottom-axis date labels shown regardless of how
    // far back the history goes, so long histories don't turn into
    // unreadable label clutter.
    final labelStep = (points.length / 10).ceil().clamp(1, 999);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
            children: [
              Expanded(
                child: Text(
                  selected == null
                      ? 'Scroll to browse, or pick a date to jump to it.'
                      : '${_dayLabel(selected.day, full: true)} — Rs '
                          '${_formatMoney(selected.revenue)} · '
                          '${selected.orderCount} order${selected.orderCount == 1 ? '' : 's'} · '
                          '${selected.itemsSold} item${selected.itemsSold == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                color: AppColors.primary,
                tooltip: 'Pick a date',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 190,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth < 100 ? 100 : chartWidth,
                child: BarChart(
                  BarChartData(
                    maxY: chartMax.toDouble(),
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        getTooltipItem: (group, _, rod, __) {
                          final p = points[group.x.toInt()];
                          return BarTooltipItem(
                            'Rs ${_formatMoney(p.revenue)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text: _dayLabel(p.day, full: true),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.spot == null) {
                          return;
                        }
                        setState(() {
                          _selectedIndex = response.spot!.touchedBarGroupIndex;
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= points.length) {
                              return const SizedBox.shrink();
                            }
                            if (i % labelStep != 0 && i != points.length - 1) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _dayLabel(points[i].day),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < points.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: points[i].revenue.toDouble(),
                              color: i == _selectedIndex
                                  ? AppColors.accent
                                  : (points[i].revenue > 0
                                      ? AppColors.primary
                                      : AppColors.muted),
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _dayLabel(DateTime d, {bool full = false}) {
    if (full) return '${_weekdayLabels[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}';
    return '${d.day}/${d.month}';
  }
}

/// Line chart, one point per month (last 6 months, oldest to newest). A
/// month with zero delivered-order revenue still gets a point on the
/// line at y=0, rather than being skipped.
class _MonthlySalesChart extends StatelessWidget {
  final List<MonthlySalesPoint> points;
  const _MonthlySalesChart({required this.points});

  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final maxRevenue = points.fold<int>(0, (m, p) => p.revenue > m ? p.revenue : m);
    final chartMax = maxRevenue == 0 ? 100 : (maxRevenue * 1.2).ceil();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
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
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: chartMax.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartMax / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.muted,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary,
              getTooltipItems: (spots) => spots.map((s) {
                final p = points[s.x.toInt()];
                return LineTooltipItem(
                  'Rs ${_formatMoney(p.revenue)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: '${_monthLabels[p.monthStart.month - 1]} ${p.monthStart.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _monthLabels[points[i].monthStart.month - 1],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].revenue.toDouble()),
              ],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
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
