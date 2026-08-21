import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/orders_provider.dart';
import '../../domain/reports_provider.dart';
import 'package:go_router/go_router.dart';
import '../../domain/users_provider.dart';
import '../../../listings/domain/listings_provider.dart';

/// Admin dashboard — basic metrics + moderation entry points (Doc 5 §22).
/// TODO Phase 10/11: gate this screen behind an admin role check once
/// real Auth + user roles exist. Currently reachable from Profile menu
/// for testing only.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final reports = ref.watch(reportsProvider);
    final usersAsync = ref.watch(usersStreamProvider);
    final listingsAsync = ref.watch(listingsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _metricCard('Users', '${usersAsync.asData?.value.length ?? 0}',
                      Icons.people_outline, AppColors.primary),
                  _metricCard('Active Listings',
                      '${listingsAsync.asData?.value.length ?? 0}',
                      Icons.local_offer_outlined, AppColors.accent),
                  _metricCard('Orders', '${ordersAsync.asData?.value.length ?? 0}',
                      Icons.receipt_long_outlined, const Color(0xFF0B3A6E)),
                  _metricCard('Open Reports', '${reports.length}',
                      Icons.flag_outlined, AppColors.errorText),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Moderation',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              _menuRow(
                context,
                icon: Icons.flag_outlined,
                label: 'User Reports',
                trailing: reports.isNotEmpty ? '${reports.length}' : null,
                onTap: () => context.push('/admin/reports'),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.local_offer_outlined,
                label: 'Listings',
                trailing: '${listingsAsync.asData?.value.length ?? 0}',
                onTap: () => context.push('/admin/listings'),
              ),

              const SizedBox(height: 8),                          // ADD
              _menuRow(                                            // ADD
                context,                                            // ADD
                icon: Icons.people_outline,                         // ADD
                label: 'Users',                                     // ADD
                trailing: '${usersAsync.asData?.value.length ?? 0}', // ADD
                onTap: () => context.push('/admin/users'),           // ADD
              ),                                                    // ADD
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        String? trailing,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.errorText),
                ),
              ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.neutral200),
          ],
        ),
      ),
    );
  }
}