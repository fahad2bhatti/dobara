import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Placeholder — full search + filters UI comes in Phase 2.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Explore')),
      body: const Center(
        child: Text(
          'Search & filters coming soon',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
