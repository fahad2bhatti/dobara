import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Placeholder — real wishlist (backed by Firestore) comes later,
/// once listings + auth are wired up.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wishlist')),
      body: const Center(
        child: Text(
          'Your saved items will appear here',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
