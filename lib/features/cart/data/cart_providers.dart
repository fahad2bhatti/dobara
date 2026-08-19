import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/cart_model.dart';
import '../../../shared/models/product_model.dart';
import '../../auth/domain/auth_provider.dart';
import 'cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) => CartRepository());

/// Live cart items for the signed-in user. Empty list when signed out.
final cartStreamProvider = StreamProvider<List<CartItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(cartRepositoryProvider).watchCart(user.uid);
});

/// Total item count (sum of quantities) — drives the header badge.
final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartStreamProvider).asData?.value ?? const [];
  return items.fold<int>(0, (sum, item) => sum + item.quantity);
});

/// Subtotal in PKR across all cart items.
final cartTotalProvider = Provider<int>((ref) {
  final items = ref.watch(cartStreamProvider).asData?.value ?? const [];
  return items.fold<int>(0, (sum, item) => sum + item.subtotal);
});

/// Write-side actions (add/update/remove/clear), separate from the
/// read-side stream above.
class CartActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> addItem(Product product) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final item = CartItem(
      listingId: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      size: product.size,
      sellerId: product.seller.id,
      sellerName: product.seller.name,
    );
    await ref.read(cartRepositoryProvider).addItem(user.uid, item);
  }

  Future<void> updateQuantity(String listingId, int quantity) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(cartRepositoryProvider)
        .updateQuantity(user.uid, listingId, quantity);
  }

  Future<void> removeItem(String listingId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(cartRepositoryProvider).removeItem(user.uid, listingId);
  }

  Future<void> clearCart() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(cartRepositoryProvider).clearCart(user.uid);
  }

  /// Whether a listing is currently in the cart — used to disable the
  /// "Add to Cart" button and show "In Cart" instead.
  bool contains(String listingId) {
    final items = ref.read(cartStreamProvider).asData?.value ?? const [];
    return items.any((i) => i.listingId == listingId);
  }
}

final cartActionsProvider = NotifierProvider<CartActions, void>(CartActions.new);