import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../items/domain/catalog_item.dart';
import '../../../items/presentation/providers/items_providers.dart';
import '../../../orders/domain/order_line_item.dart';

/// Shared between the item-list header and each row so the Quantity/Live
/// values line up directly under their column headings.
const _quantityColumnWidth = 70.0;
const _statusColumnWidth = 32.0;

/// The item list card — green-header/cream-body chrome, listing each
/// line's catalog photo (looked up from the already-cached catalog by id —
/// order_items doesn't store an image url itself), name, and
/// quantity/unit. No price column, ever. Shared by the Invoice/order
/// detail screen and the post-Place-Order success screen.
class OrderItemsCard extends ConsumerWidget {
  const OrderItemsCard({super.key, required this.lines});

  final List<OrderLineItem> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(catalogProvider).valueOrNull ?? const <CatalogItem>[];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recognizedOrder,
                    style: TextStyle(
                      color: AppColors.ctaText,
                      fontSize: 12,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                      fontFamilyFallback: AppTextStyles.devanagariFallback,
                    ),
                  ),
                ),
                SizedBox(
                  width: _quantityColumnWidth,
                  child: Text(
                    l10n.quantityLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ctaText,
                      fontSize: 12,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                      fontFamilyFallback: AppTextStyles.devanagariFallback,
                    ),
                  ),
                ),
                SizedBox(
                  width: _statusColumnWidth,
                  child: Text(
                    l10n.liveLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 12,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                      fontFamilyFallback: AppTextStyles.devanagariFallback,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: lines.length,
            separatorBuilder: (_, _) => const Divider(color: AppColors.cardBorder, height: 1),
            itemBuilder: (context, index) {
              final line = lines[index];
              final imageUrl = _findImageUrl(catalog, line.itemId);
              return _LineItemRow(line: line, imageUrl: imageUrl);
            },
          ),
        ],
      ),
    );
  }

  String? _findImageUrl(List<CatalogItem> catalog, String? itemId) {
    if (itemId == null) return null;
    for (final item in catalog) {
      if (item.id == itemId) return item.imageUrl;
    }
    return null;
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.line, required this.imageUrl});

  final OrderLineItem line;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: imageUrl == null || imageUrl!.isEmpty
                  ? _imageFallback()
                  : CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, _, _) => _imageFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              line.itemName,
              style: AppTextStyles.itemName.copyWith(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _quantityColumnWidth,
            child: Text(
              '${line.quantity} ${line.unit}'.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 12,
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: _statusColumnWidth,
            child: Center(
              child: SvgPicture.asset('assets/icons/icon_check.svg', width: 17, height: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.inputBackground,
      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.placeholder, size: 18),
    );
  }
}
