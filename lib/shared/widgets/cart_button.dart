import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

/// Bare icon when empty; a red badge showing the actual selected count
/// when the cart has items — per explicit instruction that the number of
/// items selected on the Shop grid should be visible on the cart icon
/// (supersedes the earlier "dot only, no number" reading of the Figma
/// spec).
class CartButton extends StatelessWidget {
  const CartButton({super.key, required this.itemCount, required this.onTap});

  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: itemCount > 0 ? 'Cart, $itemCount items' : 'Cart, empty',
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SvgPicture.asset(
                'assets/icons/icon_cart.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.placeholder, BlendMode.srcIn),
              ),
              if (itemCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        itemCount > 99 ? '99+' : '$itemCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
