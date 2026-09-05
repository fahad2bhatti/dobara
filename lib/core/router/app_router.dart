import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/listings/presentation/screens/explore_screen.dart';
import '../../features/listings/presentation/screens/create_listing_screen.dart';
import '../../features/listings/presentation/screens/wishlist_screen.dart';
import '../../features/listings/presentation/screens/listing_detail_screen.dart';
import '../../features/listings/presentation/screens/my_listings_screen.dart';
import '../../features/listings/presentation/screens/edit_listing_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/listings_moderation_screen.dart';
import '../../features/admin/presentation/screens/reports_screen.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/order_model.dart';
import 'app_shell_scaffold.dart';
import '../../features/admin/presentation/screens/users_list_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_order_update_screen.dart';
import '../../features/admin/presentation/screens/all_reviews_screen.dart';
import '../../features/admin/presentation/screens/admin_analytics_screen.dart';
import '../../features/reviews/presentation/screens/review_form_screen.dart';
import '../../shared/models/review_model.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/manage_addresses_screen.dart';
import '../../features/settings/presentation/screens/change_password_screen.dart';
import '../../features/settings/presentation/screens/notification_settings_screen.dart';
import '../../features/settings/presentation/screens/about_help_screen.dart';
import '../../features/settings/presentation/screens/delete_account_screen.dart';

/// Routes that require a signed-in user. Home, Explore, and Wishlist
/// stay open to guest browsing per product decision.
const _protectedPaths = [
  '/sell',
  '/cart',
  '/checkout',
  '/profile',
  '/settings',
  '/my-listings',
  '/order-history',
  '/admin',
];

bool _isProtected(String location) {
  return _protectedPaths.any(
        (p) => location == p || location.startsWith('$p/'),
  );
}

/// Bridges the Riverpod auth stream to a Listenable so GoRouter
/// re-evaluates `redirect` the moment the user logs in or out ?
/// without this, login/logout wouldn't trigger navigation on its own.
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<void> _sub;

  _GoRouterRefreshStream(Stream<void> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Central route table as a Riverpod provider so `redirect` can read
/// live auth state. Add new routes here as each feature is built.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshStream = _GoRouterRefreshStream(
    ref.watch(authStateProvider.stream),
  );
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final isLoggedIn = ref.read(currentUserProvider) != null;
      final goingToAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && _isProtected(state.matchedLocation)) {
        return '/login?from=${Uri.encodeComponent(state.matchedLocation)}';
      }
      if (isLoggedIn && goingToAuthScreen) {
        return '/home';
      }

      // Admin routes need the role check too, not just signed-in status.
      // isLoggedIn is already true here if we've reached this point and
      // the path is /admin (protected paths would've redirected above).
      final isAdminRoute = state.matchedLocation == '/admin' ||
          state.matchedLocation.startsWith('/admin/');
      if (isAdminRoute && !ref.read(isAdminProvider)) {
        return '/home';
      }

      // Scope change: only admin can create/manage listings now (Dobara
      // is no longer peer-to-peer). Non-admins hitting these get bounced.
      const adminOnlyPaths = ['/sell', '/my-listings', '/edit-listing'];
      if (adminOnlyPaths.contains(state.matchedLocation) &&
          !ref.read(isAdminProvider)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Pushed from Home/Explore with `extra: product` since a full
      // Product object doesn't serialize cleanly into a URL.
      GoRoute(
        path: '/listing-detail',
        builder: (context, state) {
          final product = state.extra as Product;
          return ListingDetailScreen(product: product);
        },
      ),

      // Admin-only — pushed from My Listings with `extra: product`.
      GoRoute(
        path: '/edit-listing',
        builder: (context, state) {
          final product = state.extra as Product;
          return EditListingScreen(product: product);
        },
      ),

      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/order-history',
        builder: (context, state) => const OrderHistoryScreen(),
        routes: [
          GoRoute(
            path: 'detail', // -> /order-history/detail, extra: order
            builder: (context, state) {
              final order = state.extra as Order;
              return OrderDetailScreen(order: order);
            },
          ),
        ],
      ),

      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      GoRoute(
        path: '/review-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReviewFormScreen(
            listingId: extra['listingId'] as String,
            existing: extra['existing'] as Review?,
          );
        },
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'addresses',
            builder: (context, state) => const ManageAddressesScreen(),
          ),
          GoRoute(
            path: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutHelpScreen(),
          ),
          GoRoute(
            path: 'delete-account',
            builder: (context, state) => const DeleteAccountScreen(),
          ),
        ],
      ),

      // TODO Phase 10.5: also check isAdminProvider in redirect once
      // Admin role-gating is tackled, not just signed-in status.
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'listings',
            builder: (context, state) => const ListingsModerationScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(                                                    // ADD
            path: 'users',                                            // ADD
            builder: (context, state) => const UsersListScreen(),      // ADD
          ),
          GoRoute(
            path: 'reviews',
            builder: (context, state) => const AllReviewsScreen(),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) => const AdminAnalyticsScreen(),
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const AdminOrdersScreen(),
            routes: [
              GoRoute(
                path: 'update', // -> /admin/orders/update, extra: order
                builder: (context, state) {
                  final order = state.extra as Order;
                  return AdminOrderUpdateScreen(order: order);
                },
              ),
            ],
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sell',
                builder: (context, state) => const CreateListingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wishlist',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});