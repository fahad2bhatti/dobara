import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Empty-state Wishlist — populated once wishlist data (per-user,
/// backed by Firestore) is wired up after auth.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

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
        ),
      ),
    );
  }
}