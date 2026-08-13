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
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(storageServiceProvider));
});