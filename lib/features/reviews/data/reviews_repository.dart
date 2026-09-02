import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/review_model.dart';

class ReviewsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reviews(String listingId) =>
      _db.collection('listings').doc(listingId).collection('reviews');

  Stream<List<Review>> watchReviews(String listingId) {
    return _reviews(listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromDoc(d)).toList());
  }

  /// doc id == reviewer's uid, so this both creates a first-time review
  /// and edits an existing one — no separate update method needed.
  Future<void> submitReview(String listingId, String uid, Review review) {
    return _reviews(listingId).doc(uid).set(review.toMap());
  }

  Future<void> deleteReview(String listingId, String uid) {
    return _reviews(listingId).doc(uid).delete();
  }

  /// All reviews the given user has written, across every listing —
  /// powers the "Reviews" entry on their own Profile. Relies on the
  /// `userId` field (duplicated onto every review doc) since a
  /// collectionGroup query can't filter on doc id directly.
  Stream<List<Review>> watchMyReviews(String uid) {
    return _db
        .collectionGroup('reviews')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromDoc(d)).toList());
  }
}
