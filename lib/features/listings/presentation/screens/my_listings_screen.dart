import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/condition_badge.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/listings_provider.dart';
import 'package:go_router/go_router.dart';

/// The signed-in seller's own published listings — filters the same
/// live Firestore stream Home/Explore use, down to this user's items.
class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final listingsAsync = ref.watch(listingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Listings')),
      body: SafeArea(
        child: user == null
            ? const Center(
          child: Text('Sign in to see your listings',
              style: TextStyle(color: AppColors.textTertiary)),
        )
            : listingsAsync.when(
          data: (all) {
            final mine =
            all.where((p) => p.seller.id == user.uid).toList();
            if (mine.isEmpty) return _buildEmpty();
            return _buildList(context, ref, mine);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ),
          error: (err, _) => const Center(
            child: Text('Could not load your listings.',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 48, color: AppColors.textTertiary),
            SizedBox(height: 10),
            Text(
              'You haven\'t listed anything yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap Sell to publish your first item.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Product> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = items[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/listing-detail', extra: p),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 60,
                        height: 76,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            p.imageUrl.isEmpty
                                ? Container(
                              color: AppColors.muted,
                              child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 18,
                                  color: AppColors.textTertiary),
                            )
                                : CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                                  Container(color: AppColors.muted),
                              errorWidget: (_, _, _) => Container(
                                color: AppColors.muted,
                                child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 18,
                                    color: AppColors.textTertiary),
                              ),
                            ),
                            if (p.isSoldOut)
                              Container(
                                color: Colors.black.withValues(alpha: 0.45),
                                alignment: Alignment.center,
                                child: const Text('SOLD',
                                    style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.6)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Rs. ${_formatPrice(p.price)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          const SizedBox(height: 6),
                          ConditionBadge(grade: p.condition),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.neutral200),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/edit-listing', extra: p),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(listingsActionsProvider.notifier)
                          .setSoldOut(p.id, !p.isSoldOut),
                      icon: Icon(
                        p.isSoldOut
                            ? Icons.refresh
                            : Icons.check_circle_outline,
                        size: 15,
                      ),
                      label: Text(p.isSoldOut ? 'Mark Available' : 'Mark Sold'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.isSoldOut
                            ? AppColors.primary
                            : AppColors.warningText,
                        side: BorderSide(
                          color: p.isSoldOut
                              ? AppColors.border
                              : AppColors.warningBorder,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}