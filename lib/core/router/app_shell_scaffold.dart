import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
/// Wraps StatefulShellRoute's branch navigator with the bottom nav bar.
/// Each tab keeps its own navigation stack (so switching tabs doesn't
/// lose scroll position / pushed screens on the other tabs).
class AppShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Tapping the already-active tab pops back to its root.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
