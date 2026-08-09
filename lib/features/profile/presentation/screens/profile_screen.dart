import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Placeholder — real profile (seller stats, trust score, settings,
/// "Become a Seller" flow) comes once auth is built.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text(
          'Sign in to view your profile',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
