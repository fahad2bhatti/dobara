import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Placeholder — full guided sell flow (photos → category → condition
/// → info → price → description → preview → publish) comes in Phase 3.
class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sell')),
      body: const Center(
        child: Text(
          'Guided sell flow coming soon',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
