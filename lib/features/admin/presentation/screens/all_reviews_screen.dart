import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/review_model.dart';
import '../../../listings/domain/listings_provider.dart';
import '../../../reviews/data/reviews_providers.dart';

/// Admin-only — every review left on the platform, across every
/// listing, newest first. Shows who wrote it, when, which listing it
/// was on, and lets admin reply as the seller.
class AllReviewsScreen extends ConsumerWidget {
  const AllReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allReviewsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reviews')),
      body: SafeArea(
        child: reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load reviews: $e')),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Center(
                child: Text('No reviews on the platform yet.',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ReviewCard(review: reviews[i]),
            );
          },
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  final d = '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final t = '$hour12:${dt.minute.toString().padLeft(2, '0')} $ampm';
  return '$d · $t';
}

class _ReviewCard extends ConsumerWidget {
  final Review review;
  const _ReviewCard({required this.review});

  Future<void> _openReplyDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: review.adminReply ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(review.adminReply != null ? 'Edit Reply' : 'Reply as Seller'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Thanks for the feedback…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    if (!context.mounted) return;
    try {
      await ref.read(reviewsActionsProvider.notifier).submitAdminReply(
            review.listingId,
            review.id,
            result,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save reply: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingByIdProvider(review.listingId));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Which listing this review was left on.
          listingAsync.when(
            loading: () => const SizedBox(
              height: 14,
              child: Center(
                child: SizedBox(
                    width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (product) {
              if (product == null) {
                return const Text('On: (listing removed)',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary));
              }
              return GestureDetector(
                onTap: () => context.push('/listing-detail', extra: product),
                child: Text(
                  'On: ${product.name}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDateTime(review.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (star) => Icon(
                star < review.rating ? Icons.star : Icons.star_border,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, j) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.photoUrls[j],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (review.adminReply != null && review.adminReply!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELLER REPLY',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text(review.adminReply!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _openReplyDialog(context, ref),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                review.adminReply != null && review.adminReply!.isNotEmpty
                    ? 'Edit Reply'
                    : 'Reply',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
