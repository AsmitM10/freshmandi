import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Admin section's own 4-tab bottom nav (Home/Stats/Parties/Items) — no
/// floating voice button, unlike the restaurant-side [BottomNavBar]. Home
/// and Items reuse the exact same nav_home*/nav_shop* SVGs as the
/// restaurant nav (Items being the admin's catalog-management equivalent of
/// Shop); Stats and Parties are new icons only exported in one color, so
/// they're tinted via [ColorFilter] instead of file-swapping like the rest.
/// Same bar height/width as the restaurant side's [BottomNavBar] — that
/// one's [AppSpacing.bottomNavHeight] also reserves 24px above the bar for
/// its floating voice button to poke into, which this bar doesn't have, so
/// the visible strip itself is that total minus those 24px.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: AppShadows.card,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          // BottomNavBar's own bar sits at `top: 24` within its
          // AppSpacing.bottomNavHeight-tall SizedBox (that gap is reserved
          // for its floating voice button) — same 24 subtracted here.
          height: AppSpacing.bottomNavHeight - 24,
          child: Row(
            children: [
              Expanded(
                child: _AdminNavItem(
                  svgAsset: currentIndex == 0
                      ? 'assets/icons/nav_home.svg'
                      : 'assets/icons/nav_home_outline.svg',
                  label: 'Home',
                  isActive: currentIndex == 0,
                  tint: false,
                  onTap: () => onTabSelected(0),
                ),
              ),
              Expanded(
                child: _AdminNavItem(
                  svgAsset: 'assets/icons/nav_admin_stats.svg',
                  label: 'Stats',
                  isActive: currentIndex == 1,
                  tint: true,
                  onTap: () => onTabSelected(1),
                ),
              ),
              Expanded(
                child: _AdminNavItem(
                  svgAsset: 'assets/icons/nav_admin_parties.svg',
                  label: 'Parties',
                  isActive: currentIndex == 2,
                  tint: true,
                  onTap: () => onTabSelected(2),
                ),
              ),
              Expanded(
                child: _AdminNavItem(
                  svgAsset: currentIndex == 3
                      ? 'assets/icons/nav_shop_filled.svg'
                      : 'assets/icons/nav_shop.svg',
                  label: 'Items',
                  isActive: currentIndex == 3,
                  tint: false,
                  onTap: () => onTabSelected(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.svgAsset,
    required this.label,
    required this.isActive,
    required this.tint,
    required this.onTap,
  });

  final String svgAsset;
  final String label;
  final bool isActive;
  final bool tint;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgAsset,
              width: 24,
              height: 24,
              colorFilter: tint
                  ? ColorFilter.mode(color, BlendMode.srcIn)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.navLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
