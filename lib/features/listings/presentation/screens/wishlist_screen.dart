import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../wishlist/data/wishlist_providers.dart';
import '../../../../shared/widgets/product_card.dart';

/// Saved items — real per-user Firestore wishlist. Tap the heart on
/// any listing (Home/Explore grid or Listing Detail) to save it here.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const _SignInPrompt();
    }

    // Watch the ids stream so the grid updates live as items are
    // added/removed, and to distinguish "loading" from "empty".
    final idsAsync = ref.watch(wishlistIdsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Items'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: idsAsync.when(
          loading: () =>
          const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Could not load your saved items.\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
          ),
          data: (ids) {
            if (ids.isEmpty) return const _EmptyState();
            final products = ref.watch(wishlistProductsProvider);
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return ProductCard(
                  product: p,
                  onTap: () => context.push('/listing-detail', extra: p),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 52,
                color: AppColors.textSecondary.withValues(alpha: 0.35)),
            const SizedBox(height: 10),
            const Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the heart on any listing to save items you love.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border,
                    size: 52,
                    color: AppColors.textSecondary.withValues(alpha: 0.35)),
                const SizedBox(height: 10),
                const Text(
                  'Sign in to save items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your wishlist is saved to your account across devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Sign In',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
