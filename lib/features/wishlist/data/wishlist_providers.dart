import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../listings/domain/listings_provider.dart';
import 'wishlist_repository.dart';

final wishlistRepositoryProvider =
Provider<WishlistRepository>((ref) => WishlistRepository());

/// Set of saved listing ids for the signed-in user. Empty when signed out.
final wishlistIdsStreamProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <String>{});
  return ref.watch(wishlistRepositoryProvider).watchWishlistIds(user.uid);
});

/// The signed-in user's saved products — combines the wishlist id set
/// with the live listings stream so cards always show current price,
/// photos, and sold-out state (not a stale snapshot from when saved).
final wishlistProductsProvider = Provider<List<Product>>((ref) {
  final ids = ref.watch(wishlistIdsStreamProvider).asData?.value ?? const {};
  if (ids.isEmpty) return const [];
  final listings = ref.watch(listingsStreamProvider).asData?.value ?? const [];
  return listings.where((p) => ids.contains(p.id)).toList();
});

final wishlistCountProvider =
Provider<int>((ref) => ref.watch(wishlistProductsProvider).length);

class WishlistActions extends Notifier<void> {
  @override
  void build() {}

  bool contains(String listingId) {
    final ids = ref.read(wishlistIdsStreamProvider).asData?.value ?? const {};
    return ids.contains(listingId);
  }

  Future<void> toggle(String listingId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(wishlistRepositoryProvider);
    if (contains(listingId)) {
      await repo.remove(user.uid, listingId);
    } else {
      await repo.add(user.uid, listingId);
    }
  }
}

final wishlistActionsProvider =
NotifierProvider<WishlistActions, void>(WishlistActions.new);
