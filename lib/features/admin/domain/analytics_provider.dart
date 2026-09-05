import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../listings/domain/listings_provider.dart';

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
