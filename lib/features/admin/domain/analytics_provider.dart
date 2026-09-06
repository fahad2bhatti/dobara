import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/order_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../listings/domain/listings_provider.dart';
import '../../orders/domain/orders_provider.dart';

/// Foundation for the admin Analytics screen (built out phase by phase).
/// Phase 1 only adds what wasn't already derivable from existing data —
/// everything else (revenue, items sold, daily/monthly sales, top
/// category, order status breakdown) can be computed directly from
/// `adminOrdersStreamProvider` + `listingsStreamProvider`, already wired
/// elsewhere, so no new providers are needed for those until the screen
/// that consumes them is actually built in a later phase.

/// Listings sorted by viewCount, highest first — powers the "Most
/// Viewed" analytics card. Admin-only; empty for everyone else so a
/// regular buyer never triggers this sort/read for no reason.
final mostViewedListingsProvider = Provider<List<Product>>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  if (!isAdmin) return const [];

  final listings = ref.watch(listingsStreamProvider).asData?.value ?? const [];
  final sorted = [...listings]..sort((a, b) => b.viewCount.compareTo(a.viewCount));
  return sorted;
});

// ── Phase 2 — core stats ──────────────────────────────────────────
//
// Revenue and "sold" counts only ever come from **delivered** orders —
// a placed-but-not-yet-delivered order isn't revenue yet, and a
// cancelled one never was. This one list is reused by every stat below
// so they all agree with each other, instead of five separate filters
// that could quietly drift apart.

/// Delivered orders only — the shared basis for every revenue/sales
/// stat below. Empty for non-admins.
final _deliveredOrdersProvider = Provider<List<Order>>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  if (!isAdmin) return const [];
  final orders = ref.watch(adminOrdersStreamProvider).asData?.value ?? const [];
  return orders.where((o) => o.status == OrderStatus.delivered).toList();
});

/// Total revenue (PKR) — sum of `total` across delivered orders only.
final totalRevenueProvider = Provider<int>((ref) {
  final delivered = ref.watch(_deliveredOrdersProvider);
  return delivered.fold<int>(0, (sum, o) => sum + o.total);
});

/// Total items sold — sum of item quantities across delivered orders.
final totalItemsSoldProvider = Provider<int>((ref) {
  final delivered = ref.watch(_deliveredOrdersProvider);
  return delivered.fold<int>(
    0,
    (sum, o) => sum + o.items.fold<int>(0, (s, item) => s + item.quantity),
  );
});

/// Total sales — count of delivered orders (each delivered order is one
/// completed sale, regardless of how many items it contains).
final totalSalesCountProvider = Provider<int>((ref) {
  return ref.watch(_deliveredOrdersProvider).length;
});

/// Total orders placed, across every status (placed, cancelled, etc) —
/// distinct from totalSalesCountProvider, which counts delivered only.
final totalOrdersCountProvider = Provider<int>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  if (!isAdmin) return 0;
  return ref.watch(adminOrdersStreamProvider).asData?.value.length ?? 0;
});

/// Average order value (PKR) — total revenue ÷ number of delivered
/// orders. Zero (not NaN/crash) when there are no delivered orders yet.
final averageOrderValueProvider = Provider<int>((ref) {
  final delivered = ref.watch(_deliveredOrdersProvider);
  if (delivered.isEmpty) return 0;
  final revenue = ref.watch(totalRevenueProvider);
  return (revenue / delivered.length).round();
});

/// Order count broken down by status — every OrderStatus value is
/// present in the map even at zero, so the UI can render a fixed set of
/// rows/segments without special-casing "status never seen yet".
final orderStatusBreakdownProvider = Provider<Map<OrderStatus, int>>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  final breakdown = {for (final s in OrderStatus.values) s: 0};
  if (!isAdmin) return breakdown;

  final orders = ref.watch(adminOrdersStreamProvider).asData?.value ?? const [];
  for (final o in orders) {
    breakdown[o.status] = (breakdown[o.status] ?? 0) + 1;
  }
  return breakdown;
});

// ── Phase 3 — daily & monthly sales charts ────────────────────────
//
// Both charts are bucketed by `placedAt` (the day the order was made),
// not `statusUpdatedAt` — kept consistent with how Phase 2 already
// treats a delivered order's date. Every bucket in the window is
// present even at zero revenue, which is the whole point of the
// "which days had no sales" view the charts are for.

/// One day's revenue point for the daily sales chart. Carries order
/// count and items sold too, so tapping/jumping to a specific day can
/// show a full breakdown, not just the revenue number.
class DailySalesPoint {
  final DateTime day; // midnight, local
  final int revenue;
  final int orderCount;
  final int itemsSold;
  const DailySalesPoint(this.day, this.revenue, this.orderCount, this.itemsSold);
}

/// One month's revenue point for the monthly sales chart.
class MonthlySalesPoint {
  final DateTime monthStart; // 1st of the month, local
  final int revenue;
  const MonthlySalesPoint(this.monthStart, this.revenue);
}

const int dailyChartWindowDays = 14;
const int monthlyChartWindowMonths = 6;

/// Every day's stats from the very first delivered order up to today,
/// oldest first — one point per calendar day even for days with zero
/// sales. This backs the scrollable chart + "jump to a date" lookup,
/// so admin can inspect any day in the store's history, not just a
/// fixed recent window.
final dailySalesHistoryProvider = Provider<List<DailySalesPoint>>((ref) {
  final delivered = ref.watch(_deliveredOrdersProvider);
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);

  if (delivered.isEmpty) {
    // No sales history at all yet — still show a short recent window
    // rather than a single empty day, so the chart isn't jarring.
    return List.generate(dailyChartWindowDays, (i) {
      final day = todayMidnight.subtract(Duration(days: dailyChartWindowDays - 1 - i));
      return DailySalesPoint(day, 0, 0, 0);
    });
  }

  final revenueByDay = <DateTime, int>{};
  final ordersByDay = <DateTime, int>{};
  final itemsByDay = <DateTime, int>{};
  DateTime earliest = todayMidnight;
  for (final o in delivered) {
    final d = DateTime(o.placedAt.year, o.placedAt.month, o.placedAt.day);
    revenueByDay[d] = (revenueByDay[d] ?? 0) + o.total;
    ordersByDay[d] = (ordersByDay[d] ?? 0) + 1;
    itemsByDay[d] = (itemsByDay[d] ?? 0) +
        o.items.fold<int>(0, (s, item) => s + item.quantity);
    if (d.isBefore(earliest)) earliest = d;
  }

  final totalDays = todayMidnight.difference(earliest).inDays + 1;
  return List.generate(totalDays, (i) {
    final day = earliest.add(Duration(days: i));
    return DailySalesPoint(
      day,
      revenueByDay[day] ?? 0,
      ordersByDay[day] ?? 0,
      itemsByDay[day] ?? 0,
    );
  });
});

/// Last 14 days only — a simple slice of the full history above, kept
/// as the chart's default/collapsed view.
final dailySalesProvider = Provider<List<DailySalesPoint>>((ref) {
  final history = ref.watch(dailySalesHistoryProvider);
  if (history.length <= dailyChartWindowDays) return history;
  return history.sublist(history.length - dailyChartWindowDays);
});

/// Last 6 months of revenue, oldest first, current month included — one
/// point per calendar month even if that month had zero revenue.
final monthlySalesProvider = Provider<List<MonthlySalesPoint>>((ref) {
  final delivered = ref.watch(_deliveredOrdersProvider);
  final now = DateTime.now();

  final revenueByMonth = <DateTime, int>{};
  for (final o in delivered) {
    final m = DateTime(o.placedAt.year, o.placedAt.month);
    revenueByMonth[m] = (revenueByMonth[m] ?? 0) + o.total;
  }

  return List.generate(monthlyChartWindowMonths, (i) {
    // Subtracting months by day-count would drift across different
    // month lengths, so step via year/month arithmetic instead.
    final monthsAgo = monthlyChartWindowMonths - 1 - i;
    final totalMonthIndex = now.year * 12 + (now.month - 1) - monthsAgo;
    final monthStart = DateTime(totalMonthIndex ~/ 12, totalMonthIndex % 12 + 1);
    return MonthlySalesPoint(monthStart, revenueByMonth[monthStart] ?? 0);
  });
});

// ── Phase 4 — top performers ──────────────────────────────────────
//
// "Top-selling" is always by quantity sold, not revenue, since a
// single expensive item outselling ten cheap ones by revenue alone
// would be misleading in a "what's popular" ranking.

const int topPerformersLimit = 5;

/// A single listing's sales performance.
class ListingSalesStat {
  final String listingId;
  final String name;
  final int quantitySold;
  final int revenue;
  const ListingSalesStat({
    required this.listingId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });
}

/// A single category's sales performance.
class CategorySalesStat {
  final String category;
  final int quantitySold;
  final int revenue;
  const CategorySalesStat({
    required this.category,
    required this.quantitySold,
    required this.revenue,
  });
}

/// Top 5 listings by quantity sold, from delivered orders. Uses the
/// name frozen on the order item itself (not a live listing lookup),
/// so a listing that's since been edited or deleted still shows
/// correctly under the name it had when it sold.
final topSellingListingsProvider = Provider<List<ListingSalesStat>>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  if (!isAdmin) return const [];

  final delivered = ref.watch(_deliveredOrdersProvider);
  final qtyByListing = <String, int>{};
  final revenueByListing = <String, int>{};
  final nameByListing = <String, String>{};

  for (final o in delivered) {
    for (final item in o.items) {
      qtyByListing[item.listingId] = (qtyByListing[item.listingId] ?? 0) + item.quantity;
      revenueByListing[item.listingId] = (revenueByListing[item.listingId] ?? 0) + item.subtotal;
      nameByListing.putIfAbsent(item.listingId, () => item.name);
    }
  }

  final stats = qtyByListing.entries
      .map((e) => ListingSalesStat(
            listingId: e.key,
            name: nameByListing[e.key] ?? 'Unknown listing',
            quantitySold: e.value,
            revenue: revenueByListing[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

  return stats.take(topPerformersLimit).toList();
});

/// Top 5 categories by quantity sold. Joins each sold order item back
/// to its listing's *current* category via listingsStreamProvider — an
/// item whose listing has since been deleted can't be categorised and
/// is simply left out of this particular ranking (it's still counted
/// in totalItemsSold/totalRevenue elsewhere).
final topSellingCategoriesProvider = Provider<List<CategorySalesStat>>((ref) {
  final isAdmin = ref.watch(isAdminProvider);
  if (!isAdmin) return const [];

  final delivered = ref.watch(_deliveredOrdersProvider);
  final listings = ref.watch(listingsStreamProvider).asData?.value ?? const [];
  final categoryByListingId = {for (final l in listings) l.id: l.category};

  final qtyByCategory = <String, int>{};
  final revenueByCategory = <String, int>{};

  for (final o in delivered) {
    for (final item in o.items) {
      final category = categoryByListingId[item.listingId];
      if (category == null) continue;
      qtyByCategory[category] = (qtyByCategory[category] ?? 0) + item.quantity;
      revenueByCategory[category] = (revenueByCategory[category] ?? 0) + item.subtotal;
    }
  }

  final stats = qtyByCategory.entries
      .map((e) => CategorySalesStat(
            category: e.key,
            quantitySold: e.value,
            revenue: revenueByCategory[e.key] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

  return stats.take(topPerformersLimit).toList();
});
