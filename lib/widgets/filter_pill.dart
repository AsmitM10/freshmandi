import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Filter/category pill button — selected = solid blue (AppColors.secondary)
/// with white text, unselected = a faint green tint (AppColors.inputBackground)
/// with dark text. Used for both the Orders status filter and the Items
/// category filter, replacing the default ChoiceChip (which picked up the
/// wrong green from the admin theme's ColorScheme.secondary).
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: ShapeDecoration(
            color: selected ? AppColors.secondary : AppColors.inputBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.secondaryText,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
