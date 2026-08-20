import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Figma spec section S: Selected = navy bg + white text, Unselected =
/// light green tint bg + dark text. Pill radius isn't given explicitly
/// (flagged gap) — using a fully rounded shape, the conventional default
/// for a chip component.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.secondary : AppColors.inputBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.ctaText : AppColors.primaryText,
              fontFamilyFallback: AppTextStyles.devanagariFallback,
            ),
          ),
        ),
      ),
    );
  }
}
