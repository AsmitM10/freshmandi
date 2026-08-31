import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

/// Bottom navigation shell — Home / Orders / Items / Customers / Money /
/// More, matching the approved simplified nav (Suppliers, Delivery, Offers,
/// Purchases, Expenses, Money Out and Stock were removed from nav entirely,
/// not just hidden — see README.md).
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    (route: '/admin/dashboard', icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (route: '/admin/orders', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders'),
    (route: '/admin/items', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2, label: 'Items'),
    (route: '/admin/customers', icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Customers'),
    (route: '/admin/transactions', icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet, label: 'Money'),
  ];

  int _indexForLocation(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) return i;
    }
    return -1; // "More" destinations (settings, reports, etc.) or unknown
  }

  void _openMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/admin/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/admin/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_outlined),
              title: const Text('Sales register'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/admin/sales');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/admin/notifications');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) {
          if (i == _tabs.length) {
            _openMoreSheet(context);
            return;
          }
          context.go(_tabs[i].route);
        },
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), selectedIcon: Icon(tab.selectedIcon), label: tab.label),
          const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
