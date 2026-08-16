import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/items/domain/catalog_item.dart';
import '../../features/orders/presentation/providers/cart_providers.dart';

/// The reusable item card — identical across Shop grids AND search
/// results, per the explicit "no separate search-result UI" rule.
///
/// Exactly two states, per explicit instruction (superseding the earlier
/// inline +/- quantity stepper): default (light, unselected) and selected
/// (solid navy). Tapping the button is a toggle, not a counter — it adds
/// the item at quantity 1 or removes it entirely; adjusting the quantity
/// beyond that happens later (Cart/Review), not on this grid. The cart
/// icon's badge count is what increases as items are selected here.
///
/// Fixed-size Container with `clipBehavior: Clip.antiAlias` and
/// absolutely-positioned children (matching the given Figma coordinates)
/// rather than a flexible Column — a flexible layout here previously let
/// content overflow the card's declared height unclipped, which bled
/// visually into the space above the bottom nav bar.
///
/// Card background is opaque (`AppColors.surfaceWhite`) rather than the
/// literal 10%-alpha white from the Figma export — the same adaptation
/// made for Home's category cards, since 10%-alpha white over this app's
/// off-white page background reads as flat gray, not the frosted-glass
/// look the design assumed against a colored backdrop.
class ItemCard extends ConsumerWidget {
  const ItemCard({super.key, required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(cartQuantityProvider(item.id));
    final isSelected = quantity > 0;
    final cart = ref.read(cartProvider.notifier);

    return Container(
      height: AppSpacing.itemCardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Opacity(
        opacity: item.isAvailable ? 1 : 0.5,
        child: Stack(
          children: [
            Positioned(
              left: 39,
              top: 13,
              width: AppSpacing.itemCardImageWidth,
              height: AppSpacing.itemCardImageHeight,
              child: _ItemImage(url: item.imageUrl),
            ),
            Positioned(
              left: 10,
              top: 104,
              width: 145,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.isAvailable)
                    _SelectButton(
                      isSelected: isSelected,
                      onTap: () {
                        if (isSelected) {
                          cart.remove(item.id);
                        } else {
                          cart.increment(item.id);
                        }
                      },
                    ),
                ],
              ),
            ),
            if (!item.isAvailable)
              const Positioned(
                left: 10,
                right: 10,
                top: 104,
                child: Text(
                  'Unavailable',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isSelected ? 'Remove from order' : 'Add to order',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : const Color(0x0A4A8754),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            Icons.add,
            size: 16,
            color: isSelected ? AppColors.ctaText : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.fill,
        placeholder: (context, _) => const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.placeholder,
      ),
    );
  }
}
