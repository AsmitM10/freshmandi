import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/bottom_nav_bar.dart';

/// Hosts the four bottom-nav branches (Home/Shop/History/Settings) as
/// parallel navigation stacks via go_router's StatefulShellRoute, plus the
/// floating voice button on top. The voice button doesn't navigate yet —
/// the Voice screen is out of scope until Phase 8; tapping it shows a
/// "coming soon" message rather than a route to nowhere.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTabSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              onVoiceTapped: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Voice ordering is coming soon')),
                  );
              },
            ),
          ),
        ],
      ),
    );
  }
}
