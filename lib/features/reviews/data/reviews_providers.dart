import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/review_model.dart';
import '../../auth/domain/auth_provider.dart';
import 'reviews_repository.dart';

final reviewsRepositoryProvider =
Provider<ReviewsRepository>((ref) => ReviewsRepository());

/// Live reviews for one listing, newest first.
final reviewsStreamProvider =
StreamProvider.family<List<Review>, String>((ref, listingId) {
  return ref.watch(reviewsRepositoryProvider).watchReviews(listingId);
});

class ReviewStats {
  final double average;
  final int count;
  const ReviewStats({required this.average, required this.count});
}

final reviewStatsProvider =
Provider.family<ReviewStats, String>((ref, listingId) {
  final reviews = ref.watch(reviewsStreamProvider(listingId)).asData?.value ?? const [];
  if (reviews.isEmpty) return const ReviewStats(average: 0, count: 0);
  final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  return ReviewStats(average: avg, count: reviews.length);
});

/// The signed-in user's own review of this listing, if they've left
/// one — used to switch the CTA between "Write a Review" and "Edit
/// Your Review", and to pre-fill the form.
final myReviewProvider = Provider.family<Review?, String>((ref, listingId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final reviews = ref.watch(reviewsStreamProvider(listingId)).asData?.value ?? const [];
  for (final r in reviews) {
    if (r.id == user.uid) return r;
  }
  return null;
});

class ReviewsActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> submit(String listingId, Review review) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(reviewsRepositoryProvider).submitReview(listingId, user.uid, review);
  }

  Future<void> delete(String listingId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(reviewsRepositoryProvider).deleteReview(listingId, user.uid);
  }
}

final reviewsActionsProvider =
NotifierProvider<ReviewsActions, void>(ReviewsActions.new);
