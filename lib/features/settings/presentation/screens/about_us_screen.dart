import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// About Us — reached from Settings. Static app-level marketing copy (not
/// restaurant-specific data), matching the Figma reference.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
                children: const [
                  _HeroRow(),
                  SizedBox(height: AppSpacing.xl),
                  _FeatureCard(),
                  SizedBox(height: AppSpacing.xl),
                  _WhoWeAreRow(),
                  SizedBox(height: AppSpacing.xl),
                  _OurMissionRow(),
                  SizedBox(height: AppSpacing.xl),
                  Text(
                    'Why Restaurants Choose Us ?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: AppSpacing.base),
                  _WhyChooseUsCard(),
                  SizedBox(height: AppSpacing.base),
                  _TrustRow(),
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
              'About Us',
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
                    TextSpan(
                      text: 'We help restaurants run their business ',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF2F3136),
                      ),
                    ),
                    TextSpan(
                      text: 'better',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage orders, deliveries, payments and customers - all in one simple app',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.placeholder,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'lib/assets/images/about_us1.png',
            width: 126,
            height: 117.5,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard();

  static const _rows = [
    ('assets/icons/icon_privacy_note.svg', 'Smart Orders', 'Manage orders easily'),
    (
      'assets/icons/icon_delivery_box.svg',
      'Smooth Deliveries',
      'Optimized routes and on-time delivery',
    ),
    ('assets/icons/icon_payment.svg', 'Secure Payments', 'Safe and quick payment tracking'),
    ('assets/icons/icon_customers.svg', 'Happy Customers', 'Better service, stronger loyalty'),
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
              _FeatureRow(iconAsset: _rows[i].$1, title: _rows[i].$2, subtitle: _rows[i].$3),
              if (i < _rows.length - 1)
                const Divider(color: AppColors.cardBorder, height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.iconAsset, required this.title, required this.subtitle});

  final String iconAsset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFE5F1E7), shape: BoxShape.circle),
            child: SvgPicture.asset(iconAsset, width: 20, height: 20),
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

class _WhoWeAreRow extends StatelessWidget {
  const _WhoWeAreRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who We Are',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We are a team of passionate problem solvers building technology that makes restaurant operations effortless.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.60),
                  fontSize: 12,
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Our mission is to empower food businesses to grow faster and serve better',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.60),
                  fontSize: 12,
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'lib/assets/images/about_us2.png',
            width: 134,
            height: 125,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _OurMissionRow extends StatelessWidget {
  const _OurMissionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset('assets/icons/icon_mission.svg', width: 88, height: 88),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our Mission',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To simplify restaurant management with intuitive technology and exceptional support, so you can focus on what you do best - serving delicious food.',
                style: TextStyle(
                  color: AppColors.placeholder,
                  fontSize: 12,
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhyChooseUsCard extends StatelessWidget {
  const _WhyChooseUsCard();

  static const _items = [
    'Easy to use and designed for restaurant workflows',
    'All-in-one solution for orders, deliveries and payments',
    'Real-time insights to help you make better decisions',
    'Reliable support, whenever you need us',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/icon_check.svg',
                  width: 17,
                  height: 12,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _items[i],
                    style: TextStyle(
                      color: AppColors.ctaText,
                      fontSize: 14,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFFA4FCA8), shape: BoxShape.circle),
            child: SvgPicture.asset('assets/icons/icon_verify.svg', width: 24, height: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Business, One Priority',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 16,
                    fontFamily: AppTextStyles.urbanistFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We are committed to the security of your data and the success of your business.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
