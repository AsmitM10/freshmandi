import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/items/domain/item_category.dart';

/// "Browse Category" card — shared by Home and Cart's "Add more" section.
///
/// The exact oversized/rotated placement from the Figma export was tuned
/// for a solid placeholder box, not the real product photos — each photo
/// has a lot of empty background space at the top with the produce basket
/// clustered at the bottom, so reusing that transform crops mostly into
/// empty space instead of the produce. Filling the card and anchoring to
/// the bottom keeps the actual basket visible instead; rotation is dropped
/// since these photos have a visible basket edge that would look wrong
/// tilted (unlike an abstract full-bleed texture the original transform
/// assumed).
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  final ItemCategory category;
  final VoidCallback onTap;

  static String _assetFor(ItemCategory category) {
    switch (category) {
      case ItemCategory.indianVegetables:
        return 'lib/assets/images/indianveg.png';
      case ItemCategory.fruits:
        return 'lib/assets/images/fruits.png';
      case ItemCategory.exoticVegetables:
        return 'lib/assets/images/exoticveg.png';
    }
  }

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
