import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore CRUD for a user's wishlist at wishlist/{uid}/items/{listingId}.
/// Docs just mark presence (doc id = listingId) — the actual product
/// data (name, price, photos...) is looked up live from the listings
/// collection so the wishlist always reflects the current listing
/// state (price changes, sold-out, edits) rather than a stale snapshot.
class WishlistRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection('wishlist').doc(uid).collection('items');

  /// Live stream of the signed-in user's saved listing ids.
  Stream<Set<String>> watchWishlistIds(String uid) {
    return _items(uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> add(String uid, String listingId) {
    return _items(uid)
        .doc(listingId)
        .set({'savedAt': FieldValue.serverTimestamp()});
  }

  Future<void> remove(String uid, String listingId) {
    return _items(uid).doc(listingId).delete();
  }
}
