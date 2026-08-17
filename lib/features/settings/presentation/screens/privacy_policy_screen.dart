import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Privacy Policy — reached from Settings. Static informational content
/// (no user data or backend involved), matching the Figma reference.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  AppSpacing.xl,
                  16,
                  AppSpacing.bottomNavHeight + AppSpacing.base,
                ),
                children: [
                  const _HeroRow(),
                  const SizedBox(height: AppSpacing.xl),
                  const _PolicyCard(),
                  const SizedBox(height: AppSpacing.xl),
                  _ContactSupportButton(
                    onTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('Contact support is coming soon')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText, size: 20),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Privacy Policy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _HeroRow extends StatelessWidget {
  const _HeroRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'We respect your ',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: 'privacy',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We're committed to bring transparent about your data and how it's used.",
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'lib/assets/images/privacy.png',
            width: 126,
            height: 117.5,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();

  static const _rows = [
    (
      'assets/icons/icon_privacy_note.svg',
      'July 10,2026',
      'Policy updates as our practices evolve.',
    ),
    (
      'assets/icons/icon_privacy_note.svg',
      'Data We Collect & Use',
      "What we collect and how it's used.",
    ),
    (
      'assets/icons/icon_privacy_delivery.svg',
      'Sharing,Security & Retention',
      'How we share, protect and store your data.',
    ),
    (
      'assets/icons/icon_privacy_group.svg',
      'Your Rights & Policy Updates',
      'Manage your data and stay informed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < _rows.length; i++) ...[
              _PolicyRow(iconAsset: _rows[i].$1, title: _rows[i].$2, subtitle: _rows[i].$3),
              if (i < _rows.length - 1)
                const Divider(color: AppColors.cardBorder, height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.iconAsset, required this.title, required this.subtitle});

  final String iconAsset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // icon_privacy_group.svg already bakes in its own 44x44 circular
    // background; the other two are plain 24x24 glyphs that need one.
    final isSelfContained = iconAsset.contains('group');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          isSelfContained
              ? SvgPicture.asset(iconAsset, width: 44, height: 44)
              : Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF1EF),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(iconAsset, width: 24, height: 24),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 16,
                    fontFamily: AppTextStyles.urbanistFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSupportButton extends StatelessWidget {
  const _ContactSupportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Text(
              'Contact Support',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
