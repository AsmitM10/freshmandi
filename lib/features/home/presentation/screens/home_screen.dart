import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/cart_button.dart';
import '../../../../shared/widgets/category_card.dart';
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
    final l10n = AppLocalizations.of(context);
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
                                restaurantAsync.valueOrNull?.restaurantName ?? l10n.homeDefaultRestaurantName,
                                style: AppTextStyles.headingScreen.copyWith(
                                  color: AppColors.secondaryText,
                                  fontFamilyFallback: AppTextStyles.devanagariFallback,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l10n.homeGreetingSubtitle,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  fontFamilyFallback: AppTextStyles.devanagariFallback,
                                ),
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
                          onTap: () => context.push(AppRoutes.cart),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SearchBarField(
                      controller: TextEditingController(),
                      placeholder: l10n.shopSearchHint,
                      onChanged: (_) {},
                      onSubmitted: (_) => context.go(AppRoutes.shop),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.homeBrowseCategory,
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontFamilyFallback: AppTextStyles.devanagariFallback,
                      ),
                    ),
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
                      return CategoryCard(
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
                child: Text(
                  l10n.homeFrequentlyOrdered,
                  style: AppTextStyles.sectionHeading.copyWith(
                    fontFamilyFallback: AppTextStyles.devanagariFallback,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.restaurant_menu_outlined,
                message: l10n.homeFrequentlyOrderedEmpty,
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

