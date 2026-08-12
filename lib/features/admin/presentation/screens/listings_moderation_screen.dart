import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/condition_badge.dart';
import '../../../home/data/mock_products.dart';

/// Admin listing moderation view (Doc 5 §22). Uses the same mock
/// product set the rest of the app currently reads from.
/// TODO Phase 11: back this with a live Firestore listings query
/// and wire real approve/remove actions.
class ListingsModerationScreen extends StatefulWidget {
  const ListingsModerationScreen({super.key});

  @override
  State<ListingsModerationScreen> createState() =>
      _ListingsModerationScreenState();
}

class _ListingsModerationScreenState extends State<ListingsModerationScreen> {
  final Set<String> _removedIds = {};

  @override
  Widget build(BuildContext context) {
    final visible =
    mockProducts.where((p) => !_removedIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Listings')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = visible[i];
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
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AppColors.muted),
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
                    onPressed: () {
                      setState(() => _removedIds.add(p.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed "${p.name}"')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.errorText),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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