import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/presentation/screens/order_history_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../listings/presentation/screens/my_listings_screen.dart';
import '../../../listings/presentation/screens/wishlist_screen.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../orders/domain/orders_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../reviews/presentation/screens/my_reviews_screen.dart';


/// Buyer's own profile — stats card, "Become a Seller" upsell, menu.
/// Currently shows a "Guest User" placeholder; will read real user
/// data once Auth (Phase 10) is wired up.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isSignedIn = user != null;
    final isAdmin = ref.watch(isAdminProvider);

    final menuItems = <List<String>>[
      ['📦', 'My Orders'],
      if (isAdmin) ['🏷️', 'My Listings'],
      ['💗', 'Saved Items'],
      ['⭐', 'Reviews'],
      ['🔔', 'Notifications'],
      ['⚙️', 'Settings'],
      if (isAdmin) ['🛡️', 'Admin Panel'],
      ['🚪', 'Sign Out'],
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'Instrument Serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // ── Profile card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.muted,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.person_outline,
                              size: 24, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSignedIn
                                    ? (user.displayName ?? user.email ?? 'Dobara User')
                                    : 'Guest User',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSignedIn ? (user.email ?? '') : 'Lahore, Pakistan',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: isSignedIn
                              ? () {}
                              : () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.primaryForeground,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            isSignedIn ? 'Edit' : 'Sign In',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.only(top: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          _statColumn(
                            isSignedIn
                                ? '${ref.watch(totalPlatformSalesCountProvider)}'
                                : '0',
                            'Sales',
                          ),
                          _statColumn(
                            isSignedIn
                                ? '${ref.watch(completedPurchasesCountProvider)}'
                                : '0',
                            'Purchases',
                          ),
                          _statColumn(
                            isSignedIn
                                ? ref.watch(trustScoreLabelProvider)
                                : '—',
                            'Trust Score',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Menu ────────────────────────────────────
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(menuItems.length, (i) {
                    final item = menuItems[i];
                    final isLast = i == menuItems.length - 1;
                    return InkWell(
                      onTap: () {
                        if (item[1] == 'My Orders') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen(),
                            ),
                          );
                        } else if (item[1] == 'My Listings') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyListingsScreen(),
                            ),
                          );
                        } else if (item[1] == 'Admin Panel') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen(),
                            ),
                          );
                        } else if (item[1] == 'Saved Items') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WishlistScreen(),
                            ),
                          );
                        } else if (item[1] == 'Reviews') {
                          if (isSignedIn) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyReviewsScreen(),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          }
                        } else if (item[1] == 'Notifications') {
                          if (isSignedIn) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          }
                        } else if (item[1] == 'Settings') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        } else if (item[1] == 'Sign Out') {
                          if (isSignedIn) {
                            ref.read(firebaseAuthServiceProvider).signOut();
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : const Border(
                            bottom: BorderSide(
                                color: AppColors.divider, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(item[0],
                                  style: const TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item[1] == 'Sign Out' && !isSignedIn
                                    ? 'Sign In'
                                    : item[1],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppColors.neutral200),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}