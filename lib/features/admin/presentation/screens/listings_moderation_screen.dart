import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/condition_badge.dart';
import '../../../listings/domain/listings_provider.dart';

/// Admin listing moderation view (Doc 5 §22). Backed by the live
/// Firestore listings stream, with real delete wired to the same
/// collection Home/Explore/My Listings read from.
class ListingsModerationScreen extends ConsumerWidget {
  const ListingsModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(listingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Listings')),
      body: SafeArea(
        child: listingsAsync.when(
          data: (listings) => listings.isEmpty
              ? const Center(child: Text('No listings found.'))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _listingTile(context, ref, listings[i]),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('Could not load listings: $e')),
        ),
      ),
    );
  }

  Widget _listingTile(BuildContext context, WidgetRef ref, dynamic p) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 76,
              child: p.imageUrl.isEmpty
                  ? Container(
                color: AppColors.muted,
                child: const Icon(Icons.image_not_supported_outlined,
                    size: 18, color: AppColors.textTertiary),
              )
                  : CachedNetworkImage(
                imageUrl: p.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.muted),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.muted,
                  child: const Icon(Icons.image_not_supported_outlined,
                      size: 18, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${_formatPrice(p.price)} · ${p.seller.name}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 6),
                ConditionBadge(grade: p.condition),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref, p),
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.errorText),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, dynamic p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text(
            'This will permanently remove "${p.name}" from Dobara. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(listingsActionsProvider.notifier).deleteListing(p.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "${p.name}"')),
      );
    }
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