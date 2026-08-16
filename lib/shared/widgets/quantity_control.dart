import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The [-] N Unit [+] control (Figma spec section G/S). Also renders the
/// bare "+" trigger itself when [quantity] is 0 — Hidden/Visible/Loading
/// states live in one widget per the component spec's state table, rather
/// than the caller branching on quantity to pick between two widgets.
class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.quantity,
    required this.unit,
    required this.onIncrement,
    required this.onDecrement,
    this.isLoading = false,
    this.isAvailable = true,
  });

  final int quantity;
  final String unit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool isLoading;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
      );
    }

    if (quantity <= 0) {
      return _RoundIconButton(
        icon: Icons.add,
        filled: false,
        onTap: isAvailable ? onIncrement : null,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIconButton(icon: Icons.remove, filled: false, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$quantity $unit', style: AppTextStyles.bodySmall),
        ),
        _RoundIconButton(
          icon: Icons.add,
          filled: true,
          onTap: isAvailable ? onIncrement : null,
        ),
      ],
    );
  }
}

/// AddButton component (Figma spec section S): Default = light green tint
/// bg + secondary-color icon; Active (Variant2) = navy bg + white icon.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.filled, this.onTap});

  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.secondary : AppColors.inputBackground,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            icon,
            size: 16,
            color: filled ? AppColors.ctaText : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
