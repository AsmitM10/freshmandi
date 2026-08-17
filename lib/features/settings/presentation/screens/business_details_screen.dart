import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/domain/restaurant_account.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Business Details — reached from Settings. Shows the restaurant's real
/// account data (name/owner/phone/status, all that `restaurants` actually
/// stores). The Figma reference also shows a tagline, a full address, and
/// a profile photo — none of that exists in the schema yet, so those show
/// as "Not set" rather than invented text. "Edit Profile" is UI only for
/// now (no update flow wired), same "coming soon" treatment as the other
/// not-yet-built Settings rows.
class BusinessDetailsScreen extends ConsumerWidget {
  const BusinessDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(currentRestaurantProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: restaurantAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: "Couldn't load your business details.",
                  action: TextButton(
                    onPressed: () => ref.refresh(currentRestaurantProvider),
                    child: const Text('Retry'),
                  ),
                ),
                data: (restaurant) => restaurant == null
                    ? const EmptyState(
                        icon: Icons.storefront_outlined,
                        message: 'No business details found.',
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          AppSpacing.bottomNavHeight + AppSpacing.base,
                        ),
                        children: [
                          _ProfileCard(restaurant: restaurant, context: context),
                          const SizedBox(height: AppSpacing.xl),
                          Text('Account Information', style: AppTextStyles.sectionHeading),
                          const SizedBox(height: AppSpacing.base),
                          _AccountInfoCard(restaurant: restaurant),
                        ],
                      ),
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
              'Business Details',
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.restaurant, required this.context});

  final RestaurantAccount restaurant;
  final BuildContext context;

  void _comingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Editing your business profile is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront, color: Colors.white, size: 40),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: InkWell(
                      onTap: _comingSoon,
                      customBorder: const CircleBorder(),
                      child: SvgPicture.asset('assets/icons/icon_camera_badge.svg', width: 28, height: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.restaurantName,
                      style: TextStyle(
                        color: AppColors.ctaText,
                        fontSize: 20,
                        fontFamily: AppTextStyles.urbanistFontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Not set',
                      style: TextStyle(
                        color: AppColors.ctaText.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.ctaText.withValues(alpha: 0.85),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Address not set',
                            style: TextStyle(
                              color: AppColors.ctaText.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: Material(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _comingSoon,
                child: Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 14,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.restaurant});

  final RestaurantAccount restaurant;

  @override
  Widget build(BuildContext context) {
    // Email Address, Delivery Address, and FSSAI Number aren't in the
    // schema (auth is phone-only, restaurants has no address column, and
    // the FSSAI *document* restaurants upload at registration has no
    // separate license-number field) — shown as "Not set" rather than
    // fabricated values, since an invented license number or address could
    // be mistaken for real by the restaurant owner using this screen.
    const notSet = 'Not set';
    final rows = [
      (Icons.storefront_outlined, 'Restaurant Name', restaurant.restaurantName),
      (Icons.person_outline, 'Contact Person', restaurant.ownerName),
      (Icons.call_outlined, 'Phone Number', restaurant.phoneNumber),
      (Icons.mail_outline, 'Email Address', notSet),
      (Icons.location_on_outlined, 'Delivery Address', notSet),
      (Icons.description_outlined, 'FSSAI Number', notSet),
      (Icons.verified_outlined, 'Account Status', _statusLabel(restaurant.accountStatus.name)),
    ];

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
            for (var i = 0; i < rows.length; i++) ...[
              _InfoRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
              if (i < rows.length - 1)
                const Divider(color: AppColors.cardBorder, height: 1),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) => status[0].toUpperCase() + status.substring(1);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x334A8754),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(
                  value,
                  style: TextStyle(
                    color: value == 'Not set' ? AppColors.placeholder : AppColors.secondaryText,
                    fontSize: 16,
                    fontFamily: AppTextStyles.urbanistFontFamily,
                    fontStyle: value == 'Not set' ? FontStyle.italic : FontStyle.normal,
                    fontWeight: value == 'Not set' ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
