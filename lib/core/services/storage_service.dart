import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Uploads listing photos to Firebase Storage under
/// listings/{sellerId}/{listingId}/{index}.jpg and returns download URLs.
/// Uses raw bytes (putData) instead of dart:io File — this works on
/// Flutter Web as well as Android/iOS, since dart:io isn't available
/// on web.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<String>> uploadListingImages({
    required String sellerId,
    required String listingId,
    required List<Uint8List> images,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final ref = _storage
          .ref()
          .child('listings/$sellerId/$listingId/$i.jpg');
      await ref.putData(
        images[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }
}