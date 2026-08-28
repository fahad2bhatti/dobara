import 'package:cloud_firestore/cloud_firestore.dart';

/// A buyer's review of a listing. Stored at
/// listings/{listingId}/reviews/{userId} — doc id is the reviewer's uid
/// so each person can only have one review per listing (re-submitting
/// edits it rather than creating a duplicate).
class Review {
  final String id; // == reviewer's uid
  final String listingId;
  final String userName;
  final int rating; // 1-5
  final String comment;
  final List<String> photoUrls;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.listingId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.photoUrls,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'listingId': listingId,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'photoUrls': photoUrls,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Review(
      id: doc.id,
      listingId: map['listingId'] ?? '',
      userName: map['userName'] ?? 'Dobara user',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      comment: map['comment'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
