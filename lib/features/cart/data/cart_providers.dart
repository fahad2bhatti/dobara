// lib/features/cart/data/cart_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/cart_model.dart';
import 'cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository();
});

/// Live cart stream for the currently signed-in user.
/// Emits an empty list if signed out or cart doc doesn't exist yet.
final cartStreamProvider = StreamProvider<List<CartItem>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(cartRepositoryProvider).watchCart(uid);
});

/// Derived: total item count (sum of quantities) — for the header badge.
final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartStreamProvider).valueOrNull ?? [];
  return cart.fold<int>(0, (sum, item) => sum + item.quantity);
});

/// Derived: cart subtotal — for Cart/Checkout screens.
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartStreamProvider).valueOrNull ?? [];
  return cart.fold<double>(0, (sum, item) => sum + item.subtotal);
});

/// Actions notifier — screens call these, UI updates via cartStreamProvider.
class CartActions extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addItem(CartItem item) async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => ref.read(cartRepositoryProvider).addItem(uid, item),
    );
  }

  Future<void> updateQuantity(String listingId, int quantity) async {
    final uid = _uid;
    if (uid == null) return;
    state = await AsyncValue.guard(
          () => ref
          .read(cartRepositoryProvider)
          .updateQuantity(uid, listingId, quantity),
    );
  }

  Future<void> removeItem(String listingId) async {
    final uid = _uid;
    if (uid == null) return;
    state = await AsyncValue.guard(
          () => ref.read(cartRepositoryProvider).removeItem(uid, listingId),
    );
  }

  Future<void> clearCart() async {
    final uid = _uid;
    if (uid == null) return;
    state = await AsyncValue.guard(
          () => ref.read(cartRepositoryProvider).clearCart(uid),
    );
  }
}

final cartActionsProvider =
NotifierProvider<CartActions, AsyncValue<void>>(CartActions.new);