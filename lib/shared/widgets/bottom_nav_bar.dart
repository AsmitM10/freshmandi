import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/gen/app_localizations.dart';

/// Figma spec section R/S: Home + Shop cluster on the left, History +
/// Settings on the right, with a gap in the middle for the floating voice
/// button. All four tab icons are the real Vuesax SVGs exported from
/// Figma (assets/icons/nav_*.svg).
///
/// Every tab's active state is a genuinely different filled-icon SVG, not
/// a tinted copy of the outline icon (nav_home.svg / nav_home_outline.svg,
/// nav_shop_filled.svg / nav_shop.svg, and so on).
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onVoiceTapped,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onVoiceTapped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: AppSpacing.bottomNavHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // 34, not the original 24: trims the visible white bar by the
            // same 10px admin's AppShell bar was reduced by (103 -> 93),
            // without touching AppSpacing.bottomNavHeight itself — that
            // constant also sizes bottom scroll-padding on ~11 other
            // screens (Shop, History, Settings, Order Detail, ...), so
            // shrinking it directly would ripple into all of them. The
            // extra 10px just becomes more clearance above the bar, where
            // the floating voice button already sits.
            top: 34,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                boxShadow: AppShadows.card,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  // Top-aligned rather than centered — same structure as
                  // the admin AppShell's nav bar (widgets/app_shell.dart):
                  // icons sit close to the top edge (each _NavItem carries
                  // its own top padding) instead of floating mid-height.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _NavItem(
                        svgAsset: currentIndex == 0
                            ? 'assets/icons/nav_home.svg'
                            : 'assets/icons/nav_home_outline.svg',
                        label: l10n.navHome,
                        isActive: currentIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        svgAsset: currentIndex == 1
                            ? 'assets/icons/nav_shop_filled.svg'
                            : 'assets/icons/nav_shop.svg',
                        label: l10n.navShop,
                        isActive: currentIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                    ),
                    const SizedBox(
                      width: AppSpacing.voiceButtonInnerSize + AppSpacing.voiceButtonOuterPadding * 2,
                    ),
                    Expanded(
                      child: _NavItem(
                        svgAsset: currentIndex == 2
                            ? 'assets/icons/nav_history_filled.svg'
                            : 'assets/icons/nav_history.svg',
                        label: l10n.navHistory,
                        isActive: currentIndex == 2,
                        onTap: () => onTabSelected(2),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        svgAsset: currentIndex == 3
                            ? 'assets/icons/nav_settings_filled.svg'
                            : 'assets/icons/nav_settings.svg',
                        label: l10n.navSettings,
                        isActive: currentIndex == 3,
                        onTap: () => onTabSelected(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: 0, child: _VoiceButton(onTap: onVoiceTapped)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.svgAsset,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String svgAsset;
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
              SvgPicture.asset(svgAsset, width: 24, height: 24),
              const SizedBox(height: 6),
              Text(
                label,
                // Poppins has no Devanagari glyphs — falling back to Hind
                // (a Devanagari+Latin Google Font) covers Hindi labels
                // without changing how the English labels render at all.
                style: AppTextStyles.navLabel.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontFamilyFallback: AppTextStyles.devanagariFallback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating circular action button, always visible, elevated above the
/// tab strip — not a 5th tab.
class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Voice order',
      button: true,
      child: Material(
        color: AppColors.surfaceWhite,
        shape: const CircleBorder(),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.voiceButtonOuterPadding),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: AppSpacing.voiceButtonInnerSize,
              height: AppSpacing.voiceButtonInnerSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset('assets/icons/icon_mic.svg', width: 50, height: 24),
            ),
          ),
        ),
      ),
    );
  }
}
