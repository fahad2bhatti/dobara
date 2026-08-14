import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../cart/data/cart_providers.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../listings/domain/listings_provider.dart';
import '../../../listings/presentation/screens/listing_detail_screen.dart';

const List<String> _kCategories = [
  'All',
  'Men',
  'Women',
  'Shoes',
  'Bags',
  'Accessories',
  'Streetwear',
  'Vintage',
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'All';

  List<Product> _filter(List<Product> all) {
    if (_selectedCategory == 'All') return all;
    if (_selectedCategory == 'Shoes' || _selectedCategory == 'Bags') {
      return all.where((p) => p.category == _selectedCategory).toList();
    }
    if (['Men', 'Women', 'Streetwear', 'Vintage'].contains(_selectedCategory)) {
      return all.where((p) => p.category == 'Clothing').toList();
    }
    return all.where((p) => p.category == _selectedCategory).toList();
  }

  void _openProduct(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListingDetailScreen(product: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(listingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildCategories()),
            SliverToBoxAdapter(child: _buildHeroBanner()),
            SliverToBoxAdapter(child: _buildSectionTitle()),
            listingsAsync.when(
              data: (all) => _buildProductGrid(_filter(all)),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Center(
                    child: Text(
                      'Could not load listings. Check your connection.',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دوبارہ',
                    style: TextStyle(
                      fontFamily: 'Instrument Serif',
                      fontSize: 28,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    'DOBARA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _circleIconButton(Icons.notifications_outlined),
                  const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final count = ref.watch(cartCountProvider);
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                      child: _circleIconButton(
                        Icons.shopping_bag_outlined,
                        badgeCount: count > 0 ? count : null,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                SizedBox(width: 8),
                Text(
                  'Search fashion, brands, sizes...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {int? badgeCount}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.muted,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: AppColors.textSecondary),
        ),
        if (badgeCount != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _kCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = _kCategories[i];
          final selected = c == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppColors.background : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      height: 152,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=800&h=304&fit=crop&auto=format',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.transparent,
              AppColors.primary.withValues(alpha: 0.35),
              AppColors.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        padding: const EdgeInsets.all(18),
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NEW ARRIVALS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Giving Fashion\nAnother Life',
              style: TextStyle(
                fontFamily: 'Instrument Serif',
                fontSize: 22,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Curated pre-loved pieces — trusted sellers',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Trending Now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'See all',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> items) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'No items in this category yet.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, i) => ProductCard(
            product: items[i],
            onTap: () => _openProduct(items[i]),
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}