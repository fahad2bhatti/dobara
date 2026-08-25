import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

/// Index of the Sell tab within the bottom nav / StatefulShellRoute branches.
/// Keep in sync with the branch order in app_router.dart.
const _sellTabIndex = 2;

/// Wraps StatefulShellRoute's branch navigator with the bottom nav bar.
/// Each tab keeps its own navigation stack (so switching tabs doesn't
/// lose scroll position / pushed screens on the other tabs).
class AppShellScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // Scope change: only the Dobara admin account can create
          // listings. Non-admins tapping Sell get a clear message
          // instead of silently bouncing to Home via the router redirect.
          if (index == _sellTabIndex && !isAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only the Dobara team can list items right now.'),
              ),
            );
            return;
          }
          navigationShell.goBranch(
            index,
            // Tapping the already-active tab pops back to its root.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
