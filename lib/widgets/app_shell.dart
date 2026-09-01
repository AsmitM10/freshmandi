import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';

/// Bottom navigation shell — Home / Orders / Items / Parties / Money /
/// More, matching the approved simplified nav (Suppliers, Delivery, Offers,
/// Purchases, Expenses, Money Out and Stock were removed from nav entirely,
/// not just hidden — see README.md). Icons are the exported Figma SVGs
/// (assets/icons/nav_admin_*.svg) — each tab has a genuinely different
/// filled icon for its active state, not a tinted copy of the outline one,
/// same convention as the restaurant app's own BottomNavBar.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    (route: '/admin/dashboard', icon: 'assets/icons/nav_admin_home.svg', activeIcon: 'assets/icons/nav_admin_home_filled.svg', label: 'Home'),
    (route: '/admin/orders', icon: 'assets/icons/nav_admin_orders.svg', activeIcon: 'assets/icons/nav_admin_orders_filled.svg', label: 'Orders'),
    (route: '/admin/items', icon: 'assets/icons/nav_admin_items.svg', activeIcon: 'assets/icons/nav_admin_items_filled.svg', label: 'Items'),
    (route: '/admin/customers', icon: 'assets/icons/nav_admin_parties.svg', activeIcon: 'assets/icons/nav_admin_parties_filled.svg', label: 'Parties'),
    (route: '/admin/transactions', icon: 'assets/icons/nav_admin_money.svg', activeIcon: 'assets/icons/nav_admin_money_filled.svg', label: 'Money'),
  ];

  static const _moreItems = [
    (icon: Icons.settings_outlined, label: 'Settings', route: '/admin/settings'),
    (icon: Icons.bar_chart_outlined, label: 'Reports', route: '/admin/reports'),
    (icon: Icons.receipt_outlined, label: 'Sales register', route: '/admin/sales'),
    (icon: Icons.notifications_outlined, label: 'Notifications', route: '/admin/notifications'),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'More',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 4),
              for (final item in _moreItems)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    child: Icon(item.icon, size: 20),
                  ),
                  title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(item.route);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    // -1 (a "More" destination, e.g. /admin/settings) highlights the More
    // tab itself rather than defaulting to Home, so the bar always reflects
    // where you actually are.
    final currentIndex = _indexForLocation(location);
    final isMoreActive = currentIndex < 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          // Started from the restaurant app's own BottomNavBar bar height
          // (127 - 24px voice-button clearance = 103 — see
          // shared/widgets/bottom_nav_bar.dart), then trimmed 10px per
          // product feedback since admin has no floating button to clear.
          // Content is top-aligned (crossAxisAlignment.start + _NavItem's
          // own top padding) rather than vertically centered in that
          // height, so the icons sit close to the top edge.
          child: SizedBox(
            height: 93,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _tabs[i].icon,
                      activeIcon: _tabs[i].activeIcon,
                      label: _tabs[i].label,
                      isActive: !isMoreActive && currentIndex == i,
                      onTap: () => context.go(_tabs[i].route),
                    ),
                  ),
                Expanded(
                  child: _NavItem(
                    icon: 'assets/icons/nav_admin_more.svg',
                    activeIcon: 'assets/icons/nav_admin_more_filled.svg',
                    label: 'More',
                    isActive: isMoreActive,
                    onTap: () => _openMoreSheet(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String icon;
  final String activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.secondary : AppColors.placeholder;
    return Semantics(
      label: label,
      selected: isActive,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(isActive ? activeIcon : icon, width: 24, height: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
