import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/cart_button.dart';
import '../../../../shared/widgets/category_chip.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/item_card.dart';
import '../../../../shared/widgets/search_bar_field.dart';
import '../../../orders/presentation/providers/cart_providers.dart';
import '../../domain/catalog_item.dart';
import '../../domain/item_category.dart';
import '../providers/items_providers.dart';

/// Category switching is tab state within this one screen (per the Figma
/// spec's own recommendation in section 25), not separate routes — no
/// navigation happens when tapping a category chip.
///
/// Search operates *within* the selected category rather than replacing
/// it: the chips stay visible and interactive while searching, and typing
/// narrows the current category's grid instead of swapping to a separate
/// whole-catalog results view. Both filters run client-side over one cached
/// catalog fetch (filteredItemsProvider) — no per-keystroke or
/// per-category-tap network request. Same ItemCard grid throughout; no
/// item-detail navigation anywhere on this screen, per the explicit
/// "Search Result -> Item Detail navigation MUST NOT be implemented" rule.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  void _handleSearchCleared() {
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartTotalCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shop',
                      style: AppTextStyles.headingScreen.copyWith(
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  CartButton(
                    itemCount: cartCount,
                    onTap: () => context.push(AppRoutes.cart),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchBarField(
                controller: _searchController,
                onChanged: _handleSearchChanged,
                onCleared: _handleSearchCleared,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryChipRow(),
            const SizedBox(height: AppSpacing.md),
            const Expanded(child: _FilteredGrid()),
          ],
        ),
      ),
    );
  }
}

class _CategoryChipRow extends ConsumerWidget {
  const _CategoryChipRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ItemCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = ItemCategory.values[index];
          return CategoryChip(
            label: category.label,
            isSelected: category == selected,
            onTap: () => ref.read(selectedCategoryProvider.notifier).state = category,
          );
        },
      ),
    );
  }
}

class _FilteredGrid extends ConsumerWidget {
  const _FilteredGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(filteredItemsProvider);
    final isSearching = ref.watch(searchQueryProvider).trim().isNotEmpty;

    return itemsAsync.when(
      loading: () => const LoadingState(),
      error: (error, _) => EmptyState(
        icon: Icons.wifi_off_outlined,
        message: "Couldn't load items. Check your connection and try again.",
        action: TextButton(
          onPressed: () => ref.refresh(catalogProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: isSearching ? Icons.search_off_outlined : Icons.eco_outlined,
            message: isSearching
                ? 'No items match your search.'
                : 'No items in this category yet.',
          );
        }
        return _ItemGrid(items: items);
      },
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items});

  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        AppSpacing.bottomNavHeight + AppSpacing.base,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSpacing.gridColumns,
        crossAxisSpacing: AppSpacing.gridGap,
        mainAxisSpacing: AppSpacing.gridGap,
        childAspectRatio: 165 / AppSpacing.itemCardHeight,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => ItemCard(item: items[index]),
    );
  }
}
