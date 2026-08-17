import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Figma spec section R/S: Home + Shop cluster on the left, History +
/// Settings on the right, with a gap in the middle for the floating voice
/// button. All four tab icons are the real Vuesax SVGs exported from
/// Figma (assets/icons/nav_*.svg).
///
/// Active tabs use a genuinely different filled-icon SVG, not a tinted
/// copy of the outline icon — Home has both variants (nav_home.svg filled,
/// nav_home_outline.svg outline). Shop/History/Settings only have the
/// outline variant so far (still tinted navy/gray as a stand-in) until
/// their filled versions are exported from Figma too.
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
            top: 24,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                boxShadow: AppShadows.card,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        svgAsset: currentIndex == 0
                            ? 'assets/icons/nav_home.svg'
                            : 'assets/icons/nav_home_outline.svg',
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => onTabSelected(0),
                        tintColor: false,
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        svgAsset: currentIndex == 1
                            ? 'assets/icons/nav_shop_filled.svg'
                            : 'assets/icons/nav_shop.svg',
                        label: 'Shop',
                        isActive: currentIndex == 1,
                        onTap: () => onTabSelected(1),
                        tintColor: false,
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
                        label: 'History',
                        isActive: currentIndex == 2,
                        onTap: () => onTabSelected(2),
                        tintColor: false,
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        svgAsset: 'assets/icons/nav_settings.svg',
                        label: 'Settings',
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
    this.tintColor = true,
  });

  final String svgAsset;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// When the icon has its own real active/inactive SVG variants (each
  /// already authored with the right colors baked in — see Home/Shop/
  /// History), the raw SVG is rendered untouched. When only one outline
  /// SVG exists for both states (Settings, for now), it's tinted navy/gray
  /// as a stand-in until its filled variant is exported from Figma too.
  final bool tintColor;

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
              colorFilter: tintColor ? ColorFilter.mode(color, BlendMode.srcIn) : null,
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.navLabel.copyWith(color: color)),
          ],
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
