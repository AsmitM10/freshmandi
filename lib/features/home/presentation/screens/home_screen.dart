import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/cart_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/search_bar_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../items/domain/item_category.dart';
import '../../../items/presentation/providers/items_providers.dart';
import '../../../orders/presentation/providers/cart_providers.dart';

/// Home screen. Two sections from the Figma spec are intentionally not
/// rendered yet rather than filled with placeholder/fabricated numbers:
///
/// - PurchaseSummaryCard needs real invoice totals, which don't exist
///   until Phase 6 (Invoice). Showing a card with made-up ₹ amounts would
///   be worse than not showing it at all.
/// - "Frequently Ordered" needs order history (Phase 4/5) and has an open
///   product decision (#30: order-history-based vs. admin-curated) — shown
///   as an empty state until that data exists.
///
/// The top-level search bar here is a tap-to-navigate trigger into Shop's
/// live search, not a second independent search implementation — avoids
/// building the same inline-search state twice.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(currentRestaurantProvider);
    final cartCount = ref.watch(cartTotalCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurantAsync.valueOrNull?.restaurantName ?? 'Restaurant',
                                style: AppTextStyles.headingScreen.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Follow your routine for today',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        // Notification behavior/screen isn't defined anywhere
                        // in the spec (section Z #16) — icon shown, no action
                        // wired yet.
                        SvgPicture.asset(
                          'assets/icons/icon_notification.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            AppColors.placeholder,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        CartButton(
                          itemCount: cartCount,
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(content: Text('Cart is coming soon')),
                              );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SearchBarField(
                      controller: TextEditingController(),
                      onChanged: (_) {},
                      onSubmitted: (_) => context.go(AppRoutes.shop),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Browse Category', style: AppTextStyles.sectionHeading),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: AppSpacing.categoryCardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ItemCategory.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final category = ItemCategory.values[index];
                      return _CategoryCard(
                        category: category,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = category;
                          context.go(AppRoutes.shop);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text('Frequently Ordered', style: AppTextStyles.sectionHeading),
              ),
            ),
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.restaurant_menu_outlined,
                message: 'Items you order often will show up here after your first order.',
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.base),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-category background photo. The exact oversized/rotated placement
/// from the Figma export was tuned for a solid placeholder box, not these
/// real product photos — each of these photos has a lot of empty
/// background space at the top with the produce basket clustered at the
/// bottom, so reusing that transform crops mostly into empty space
/// instead of the produce. Filling the card and anchoring to the bottom
/// keeps the actual basket visible instead; rotation is dropped since
/// these photos have a visible basket edge that would look wrong tilted
/// (unlike an abstract full-bleed texture the original transform assumed).
String _assetFor(ItemCategory category) {
  switch (category) {
    case ItemCategory.indianVegetables:
      return 'lib/assets/images/indianveg.png';
    case ItemCategory.fruits:
      return 'lib/assets/images/fruits.png';
    case ItemCategory.exoticVegetables:
      return 'lib/assets/images/exoticveg.png';
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final ItemCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: AppSpacing.categoryCardWidth,
        height: AppSpacing.categoryCardHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _assetFor(category),
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned(
              left: 11,
              top: 12,
              child: SizedBox(
                width: 87,
                child: Text(
                  category.label,
                  style: AppTextStyles.categoryLabel.copyWith(color: AppColors.secondaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
