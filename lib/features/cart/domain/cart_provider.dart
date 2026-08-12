import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product_model.dart';

/// Cart state — a list of unique products. Listings are one-of-one
/// (Doc 5), so there's no quantity per item, just presence/absence.
class CartNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  void add(Product product) {
    if (state.any((p) => p.id == product.id)) return; // already in cart
    state = [...state, product];
  }

  void remove(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  void clear() => state = [];

  bool contains(String productId) => state.any((p) => p.id == productId);
}

final cartProvider = NotifierProvider<CartNotifier, List<Product>>(
  CartNotifier.new,
);

/// Convenience derived providers.
final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).length);

final cartSubtotalProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold<int>(0, (sum, p) => sum + p.price);
});