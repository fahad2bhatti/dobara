import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reviews_providers.dart';

/// "Reviews" entry on the user's own Profile — every review they've
/// written, across every listing, newest first.
class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Reviews')),
      body: SafeArea(
        child: reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load reviews: $e')),
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "You haven't written any reviews yet.\n"
                    'Reviews you leave on listings will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = reviews[i];
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.userName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (star) => Icon(
                            star < r.rating ? Icons.star : Icons.star_border,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (r.comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.comment,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                      if (r.photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: r.photoUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (context, j) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                r.photoUrls[j],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (r.adminReply != null && r.adminReply!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
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
                              Text(r.adminReply!,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
