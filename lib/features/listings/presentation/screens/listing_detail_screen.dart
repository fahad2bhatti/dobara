import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/condition_badge.dart';
import '../../../../shared/widgets/trust_score.dart';
import '../../../../shared/widgets/image_zoom_viewer.dart';
import '../../../cart/data/cart_providers.dart';
import '../../../../shared/models/report_model.dart';
import '../../../wishlist/data/wishlist_providers.dart';
import '../widgets/report_sheet.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';
import 'package:go_router/go_router.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ListingDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _imgIdx = 0;
  final PageController _pageController = PageController();

  List<String> get _images {
    final p = widget.product;
    return p.imageUrls.isNotEmpty
        ? p.imageUrls
        : ['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=520&fit=crop&auto=format'];
  }

  void _openZoomViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageZoomViewer(images: _images, initialIndex: _imgIdx),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(
                    icon: Icons.arrow_back,
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      _circleButton(
                        icon: Icons.ios_share_outlined,
                        color: AppColors.textSecondary,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      Builder(builder: (context) {
                        // Watch the stream so the heart updates live
                        // once Firestore confirms the write.
                        ref.watch(wishlistIdsStreamProvider);
                        final wish = ref
                            .read(wishlistActionsProvider.notifier)
                            .contains(p.id);
                        return _circleButton(
                          icon: wish ? Icons.favorite : Icons.favorite_border,
                          color: wish ? AppColors.accent : AppColors.textSecondary,
                          onTap: () => ref
                              .read(wishlistActionsProvider.notifier)
                              .toggle(p.id),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image gallery — swipeable, with dot indicators.
                    // Wrapped in GestureDetector so tapping any image
                    // opens the full-screen pinch-to-zoom viewer.
                    GestureDetector(
                      onTap: _openZoomViewer,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _images.length,
                                onPageChanged: (i) => setState(() => _imgIdx = i),
                                itemBuilder: (context, i) => CachedNetworkImage(
                                  imageUrl: _images[i],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (p.isSoldOut)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'SOLD OUT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              // Small zoom affordance hint, bottom-right.
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Dot indicators
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_images.length, (i) {
                          final active = i == _imgIdx;
                          return GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 6,
                              width: active ? 20 : 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.neutral300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + price row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${p.brand}${p.size != null ? ' · ${p.size}' : ''} · ${p.category}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.4,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontFamily: 'Instrument Serif',
                                          fontSize: 22,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textPrimary,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                'Rs. ${_formatPrice(p.price)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Condition panel
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: AppColors.muted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CONDITION',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ConditionBadge(
                                      grade: p.condition,
                                      size: ConditionBadgeSize.md,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p.condition.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Seller trust panel
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: AppColors.muted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 21,
                                  backgroundColor: AppColors.neutral200,
                                  backgroundImage: p.seller.avatarUrl.isEmpty
                                      ? null
                                      : CachedNetworkImageProvider(
                                    p.seller.avatarUrl,
                                  ),
                                  onBackgroundImageError:
                                  p.seller.avatarUrl.isEmpty
                                      ? null
                                      : (_, _) {},
                                  child: p.seller.avatarUrl.isEmpty
                                      ? const Icon(Icons.person_outline,
                                      size: 20, color: AppColors.textTertiary)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.seller.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.seller.completedSales} completed sales',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TrustScore(score: p.seller.trustScore),
                              ],
                            ),
                          ),

                          // Description
                          const SizedBox(height: 4),
                          const Text(
                            'DESCRIPTION',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textBody,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [p.category, p.brand]
                                .map(
                                  (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.muted,
                                  borderRadius:
                                  BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                                .toList(),
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () => showReportSheet(
                              context,
                              targetType: ReportTargetType.listing,
                              targetId: p.id,
                              targetLabel: '${p.name} · sold by ${p.seller.name}',
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '⚑ Report this listing',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textPlaceholder,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Fixed CTA bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: p.isSoldOut
                      ? null
                      : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(buyNowProduct: p),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.38),
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    p.isSoldOut ? 'Sold Out' : 'Buy Now',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Consumer(
                builder: (context, ref, _) {
                  // Watch the stream so `inCart` updates live once
                  // Firestore confirms the write.
                  ref.watch(cartStreamProvider);
                  final inCart =
                  ref.read(cartActionsProvider.notifier).contains(p.id);
                  return ElevatedButton(
                    onPressed: (p.isSoldOut || inCart)
                        ? null
                        : () async {
                      await ref
                          .read(cartActionsProvider.notifier)
                          .addItem(p);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${p.name} added to cart'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'View Cart',
                            onPressed: () => context.push('/cart'),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.muted,
                      disabledBackgroundColor: AppColors.muted,
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      inCart
                          ? 'In Cart'
                          : (p.isSoldOut ? 'Unavailable' : 'Add to Cart'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.muted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
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