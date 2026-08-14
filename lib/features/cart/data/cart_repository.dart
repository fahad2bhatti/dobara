import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/cart_model.dart';

/// Firestore CRUD for a user's cart at cart/{uid}/items/{listingId}.
class CartRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection('cart').doc(uid).collection('items');

  /// Live stream of the signed-in user's cart items.
  Stream<List<CartItem>> watchCart(String uid) {
    return _items(uid).snapshots().map(
          (snap) => snap.docs
          .map((d) => CartItem.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  /// Adds a listing to the cart, or increments quantity by 1 if it's
  /// already there (doc id = listingId, so this is a safe upsert).
  Future<void> addItem(String uid, CartItem item) async {
    final ref = _items(uid).doc(item.listingId);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.update({'quantity': FieldValue.increment(1)});
    } else {
      await ref.set(item.toMap());
    }
  }

  Future<void> updateQuantity(String uid, String listingId, int quantity) {
    if (quantity <= 0) return removeItem(uid, listingId);
    return _items(uid).doc(listingId).update({'quantity': quantity});
  }

  Future<void> removeItem(String uid, String listingId) {
    return _items(uid).doc(listingId).delete();
  }

  Future<void> clearCart(String uid) async {
    final snap = await _items(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}