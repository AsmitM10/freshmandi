import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/domain/restaurant_account.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Contact Us — reached from Settings' "Need a help?" banner and Privacy
/// Policy's "Contact Support" button. Shows the restaurant's own real
/// contact details (name/phone/email/delivery address), same data as
/// Business Details, not a wholesaler support line — none of that exists
/// in the schema (no support phone/email/hours table anywhere), so
/// nothing there is invented. FSSAI Number still isn't a real column
/// (same gap as Business Details) and shows "Not set" rather than the
/// Figma mockup's example license number.
class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

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
                  message: "Couldn't load your details.",
                  action: TextButton(
                    onPressed: () => ref.refresh(currentRestaurantProvider),
                    child: const Text('Retry'),
                  ),
                ),
                data: (restaurant) => restaurant == null
                    ? const EmptyState(
                        icon: Icons.storefront_outlined,
                        message: 'No contact details found.',
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          AppSpacing.bottomNavHeight + AppSpacing.base,
                        ),
                        children: [_ContactCard(restaurant: restaurant)],
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
              'Contact Us',
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.restaurant});

  final RestaurantAccount restaurant;

  @override
  Widget build(BuildContext context) {
    const notSet = 'Not set';
    final rows = [
      (Icons.person_outline, 'Contact Person', restaurant.ownerName),
      (Icons.call_outlined, 'Phone Number', restaurant.phoneNumber),
      (Icons.mail_outline, 'Email Address', restaurant.email ?? notSet),
      (
        Icons.location_on_outlined,
        'Delivery Address',
        restaurant.deliveryAddress ?? restaurant.billingAddress ?? notSet,
      ),
      // FSSAI Number isn't a real column yet (same gap as Business
      // Details) — shown as "Not set" rather than the Figma mockup's
      // example license number.
      (Icons.description_outlined, 'FSSAI Number', notSet),
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
              _ContactRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
              if (i < rows.length - 1) const Divider(color: AppColors.cardBorder, height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label, required this.value});

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
              color: const Color(0xFFA4FCA8),
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
