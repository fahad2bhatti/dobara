import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../domain/listings_provider.dart';
import 'listing_detail_screen.dart';

const List<String> _kExploreConditions = [
  'All',
  'Like New',
  'Excellent',
  'Good',
  'Fair',
  'Well Worn',
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String _condition = 'All';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Product> _filterResults(List<Product> all) {
    final q = _query.toLowerCase();
    return all.where((p) {
      final matchQ = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      final matchC = _condition == 'All' || p.condition.label == _condition;
      return matchQ && matchC;
    }).toList();
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
        child: Column(
          children: [
            // ── Header: title + search + condition filter chips ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore',
                    style: TextStyle(
                      fontFamily: 'Instrument Serif',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (v) => setState(() => _query = v),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search brands, styles, sizes...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPlaceholder,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kExploreConditions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (context, i) {
                        final c = _kExploreConditions[i];
                        final selected = c == _condition;
                        final colors = c != 'All'
                            ? AppColors.conditionColors[c]
                            : null;

                        return GestureDetector(
                          onTap: () => setState(() => _condition = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: selected
                                  ? (colors?.bg ?? AppColors.primary)
                                  : AppColors.muted,
                              borderRadius: BorderRadius.circular(999),
                              border: selected && colors != null
                                  ? Border.all(color: colors.border, width: 1.5)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? (colors?.text ?? AppColors.background)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Results ─────────────────────────────
            Expanded(
              child: listingsAsync.when(
                data: (all) {
                  final results = _filterResults(all);
                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.search_off,
                              size: 40, color: AppColors.textTertiary),
                          SizedBox(height: 8),
                          Text(
                            'No items found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try a different search or filter',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, i) => ProductCard(
                      product: results[i],
                      onTap: () => _openProduct(results[i]),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
                error: (err, _) => const Center(
                  child: Text(
                    'Could not load listings. Check your connection.',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}