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
