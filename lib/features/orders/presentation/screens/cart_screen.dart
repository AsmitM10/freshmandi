import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/category_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../history/presentation/widgets/order_summary_card.dart';
import '../../../items/domain/catalog_item.dart';
import '../../../items/domain/item_category.dart';
import '../../../items/presentation/providers/items_providers.dart';
import '../providers/cart_providers.dart';
import '../providers/orders_providers.dart';

/// Cart screen — pushed outside the bottom-nav shell (own header with a
/// back button and voice icon instead of the tab bar), reached from the
/// cart icon on Home/Shop or from "Repeat Order". Lists the current cart
/// selection (from `cartProvider`'s plain itemId->quantity map) joined
/// against the already-cached catalog for name/image/unit, with a
/// quantity stepper and a full remove action per row, a running item
/// count, and an "Add Item" shortcut back to Shop alongside the real
/// "Place Order" submission.
///
/// The Figma reference shows a per-item unit dropdown ("dozen"/"piece"/
/// "kilo"); the catalog only stores one fixed unit per item and there's no
/// per-order unit override in the schema, so this shows the item's real
/// unit as plain text rather than a non-functional dropdown.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop(), onVoice: () => context.push(AppRoutes.voiceOrder)),
            Expanded(
              child: catalogAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: "Couldn't load your cart. Check your connection and try again.",
                  action: TextButton(
                    onPressed: () => ref.refresh(catalogProvider),
                    child: const Text('Retry'),
                  ),
                ),
                data: (catalog) {
                  if (cartState.isEmpty) {
                    return EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      message: 'Your cart is empty.',
                      action: TextButton(
                        onPressed: () => context.go(AppRoutes.shop),
                        child: const Text('Browse Shop'),
                      ),
                    );
                  }

                  final rows = <(CatalogItem, int)>[];
                  for (final entry in cartState.quantities.entries) {
                    final item = _findCatalogItem(catalog, entry.key);
                    if (item != null) rows.add((item, entry.value));
                  }

                  // The item list itself scrolls (with a visible scrollbar)
                  // inside a bounded card; the total-items bar, Add Item and
                  // Place Order stay pinned below it inside the same card so
                  // they — and Browse Category below — are always on screen
                  // without needing to scroll the whole page first.
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: rows.length,
                                      separatorBuilder: (_, _) =>
                                          const Divider(color: AppColors.cardBorder, height: 1),
                                      itemBuilder: (context, i) =>
                                          _CartItemRow(item: rows[i].$1, quantity: rows[i].$2),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: _TotalItemsBar(count: cartState.totalItemCount),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OrderActionButton(
                                          label: 'Add Item',
                                          filled: false,
                                          onPressed: () => context.go(AppRoutes.shop),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(child: _PlaceOrderButton()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Browse Category', style: AppTextStyles.sectionHeading),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  CatalogItem? _findCatalogItem(List<CatalogItem> catalog, String itemId) {
    for (final item in catalog) {
      if (item.id == itemId) return item;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onVoice});

  final VoidCallback onBack;
  final VoidCallback onVoice;

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
              'Cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onVoice,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/icon_mic_outline.svg',
                    width: 30,
                    height: 30,
                    colorFilter: const ColorFilter.mode(AppColors.placeholder, BlendMode.srcIn),
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

class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({required this.item, required this.quantity});

  final CatalogItem item;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? _imageFallback()
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, _, _) => _imageFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.itemName.copyWith(fontSize: 16, color: AppColors.secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(item.unit, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => cart.remove(item.id),
                child: const Icon(Icons.delete_outline, color: AppColors.placeholder, size: 20),
              ),
              const SizedBox(height: 10),
              _QuantityStepper(
                quantity: quantity,
                onIncrement: () => cart.increment(item.id),
                onDecrement: quantity > 1 ? () => cart.decrement(item.id) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.inputBackground,
      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.placeholder),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onIncrement, this.onDecrement});

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.add, onTap: onIncrement),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? AppColors.placeholder.withValues(alpha: 0.4) : AppColors.secondary,
        ),
      ),
    );
  }
}

class _TotalItemsBar extends StatelessWidget {
  const _TotalItemsBar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Items',
            style: TextStyle(
              color: AppColors.ctaText,
              fontSize: 14,
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            count.toString().padLeft(2, '0'),
            style: TextStyle(
              color: AppColors.ctaText,
              fontSize: 16,
              fontFamily: AppTextStyles.urbanistFontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Submits the cart as a real order: one `orders` row + one `order_items`
/// row per line (item id/name/quantity/unit snapshotted, never a price),
/// then clears the cart and hands off to History, where the new order
/// shows up in Pending Invoice until a wholesaler generates its invoice.
class _PlaceOrderButton extends ConsumerStatefulWidget {
  const _PlaceOrderButton();

  @override
  ConsumerState<_PlaceOrderButton> createState() => _PlaceOrderButtonState();
}

class _PlaceOrderButtonState extends ConsumerState<_PlaceOrderButton> {
  bool _isSubmitting = false;

  Future<void> _handlePlaceOrder() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final orderId = await submitCartOrder(ref);
      if (!mounted) return;
      context.go('${AppRoutes.orderSuccess}/$orderId');
    } catch (error) {
      if (mounted) {
        context.push(AppRoutes.orderFailure, extra: mapErrorToAppException(error).message);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _handlePlaceOrder,
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctaText),
                  )
                : Text(
                    'Place Order',
                    style: TextStyle(
                      color: AppColors.ctaText,
                      fontSize: 14,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
