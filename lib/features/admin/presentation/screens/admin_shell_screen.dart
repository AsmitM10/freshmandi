import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/admin_bottom_nav_bar.dart';

/// Hosts the admin section's four bottom-nav branches (Home/Stats/Parties/
/// Items) as parallel navigation stacks, mirroring the restaurant side's
/// [MainShellScreen] but with the admin's own nav bar (no voice button).
class AdminShellScreen extends StatelessWidget {
  const AdminShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
