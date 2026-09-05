import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/product_model.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final _listingsCollection =
FirebaseFirestore.instance.collection('listings');

/// Live stream of all published listings, newest first.
/// Home and Explore both read from this instead of mock data.
final listingsStreamProvider = StreamProvider<List<Product>>((ref) {
  return _listingsCollection
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Product.fromDoc).toList());
});

class ListingsRepository {
  final StorageService _storage;

  ListingsRepository(this._storage);

  /// Uploads photos (if any) then writes the listing document.
  /// Returns the new listing's Firestore id.
  Future<String> publishListing({
    required String name,
    required String brand,
    required int price,
    required ConditionGrade condition,
    required String category,
    String? size,
    required String city,
    required String description,
    required Seller seller,
    List<Uint8List> images = const [],
    // TEMP: while Firebase Storage isn't set up (billing not resolved
    // yet), pass a placeholder image url and skip the upload entirely.
    // Remove this + the `images.isNotEmpty` branch below once Storage
    // is back — real picked photos will then upload normally again.
    String? placeholderImageUrl,
  }) async {
    // Reserve a doc id up front so uploaded images can be filed under it.
    final docRef = _listingsCollection.doc();

    List<String> imageUrls = [];
    if (images.isNotEmpty) {
      imageUrls = await _storage.uploadListingImages(
        sellerId: seller.id,
        listingId: docRef.id,
        images: images,
      );
    } else if (placeholderImageUrl != null) {
      imageUrls = [placeholderImageUrl];
    }

    final product = Product(
      id: docRef.id,
      name: name,
      brand: brand,
      price: price,
      condition: condition,
      imageUrls: imageUrls,
      category: category,
      size: size,
      city: city,
      description: description,
      seller: seller,
    );

    await docRef.set(product.toMap());
    return docRef.id;
  }

  Future<void> deleteListing(String listingId) {           // ADD THIS
    return _listingsCollection.doc(listingId).delete();     // ADD THIS
  }

  /// Partial update — pass only the fields that changed (e.g. price,
  /// description, or just isSoldOut for the sold-out toggle).
  Future<void> updateListing(String listingId, Map<String, dynamic> fields) {
    return _listingsCollection.doc(listingId).update(fields);
  }

  /// Single listing by id — used where only a listingId is on hand
  /// (e.g. showing "on: <product name>" against a review).
  Future<Product?> getListing(String listingId) async {
    final doc = await _listingsCollection.doc(listingId).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  /// Fire-and-forget view counter — called once when a buyer opens a
  /// listing's detail screen. Powers the "Most Viewed" analytics stat.
  /// Uses FieldValue.increment so concurrent views never race/clobber
  /// each other. Firestore rules restrict this to viewCount-only,
  /// increment-by-exactly-one updates — see firestore.rules.
  Future<void> incrementViewCount(String listingId) {
    return _listingsCollection.doc(listingId).update({
      'viewCount': FieldValue.increment(1),
    });
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(storageServiceProvider));
});

/// Fetches one listing by id — used to show "on: <product name>"
/// against a review, which only stores the listingId.
final listingByIdProvider =
FutureProvider.family<Product?, String>((ref, listingId) {
  return ref.watch(listingsRepositoryProvider).getListing(listingId);
});

class ListingsActions extends Notifier<void> {              // ADD FROM HERE
  @override
  void build() {}

  Future<void> deleteListing(String listingId) {
    return ref.read(listingsRepositoryProvider).deleteListing(listingId);
  }

  Future<void> updateListing(String listingId, Map<String, dynamic> fields) {
    return ref.read(listingsRepositoryProvider).updateListing(listingId, fields);
  }

  Future<void> setSoldOut(String listingId, bool soldOut) {
    return updateListing(listingId, {'isSoldOut': soldOut});
  }

  /// Called once per Listing Detail open. Swallows errors deliberately —
  /// a failed view-count bump should never block or interrupt browsing.
  Future<void> recordView(String listingId) async {
    try {
      await ref.read(listingsRepositoryProvider).incrementViewCount(listingId);
    } catch (_) {
      // best-effort only
    }
  }
}

final listingsActionsProvider =
NotifierProvider<ListingsActions, void>(ListingsActions.new);  // TO HERE