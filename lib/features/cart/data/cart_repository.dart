// lib/features/cart/data/cart_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/cart_model.dart';

class CartRepository {
  final FirebaseFirestore _db;

  CartRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // Matches deployed rule: match /cart/{userId}/items/{itemId}
  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) =>
      _db.collection('cart').doc(uid).collection('items');

  /// Live stream of the user's cart items.
  Stream<List<CartItem>> watchCart(String uid) {
    return _itemsRef(uid).snapshots().map((snap) {
      return snap.docs.map((d) => CartItem.fromMap(d.data())).toList();
    });
  }

  /// Adds an item. If the listing is already in the cart, bumps quantity
  /// instead of creating a duplicate -- doc ID is the listingId itself.
  Future<void> addItem(String uid, CartItem item) async {
    final ref = _itemsRef(uid).doc(item.listingId);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.update({
        'quantity': FieldValue.increment(item.quantity),
      });
    } else {
      await ref.set(item.toMap());
    }
  }

  Future<void> updateQuantity(String uid, String listingId, int quantity) async {
    if (quantity <= 0) {
      return removeItem(uid, listingId);
    }
    await _itemsRef(uid).doc(listingId).update({'quantity': quantity});
  }

  Future<void> removeItem(String uid, String listingId) async {
    await _itemsRef(uid).doc(listingId).delete();
  }

  /// Called after successful checkout, or on manual "clear cart".
  Future<void> clearCart(String uid) async {
    final snap = await _itemsRef(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}