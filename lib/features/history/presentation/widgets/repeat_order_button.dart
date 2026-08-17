import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/presentation/providers/cart_providers.dart';
import '../../../orders/presentation/providers/orders_providers.dart';

/// Loads a historical order's items into the current cart draft and hands
/// off to the Cart screen, where quantities can be adjusted before Place
/// Order.
///
/// Replaces the cart outright rather than merging with whatever was
/// already selected — "repeat this order" reads as "make my draft match
/// this order", not "add this order on top of my current selection".
/// Skips any line whose catalog item was later deleted (item_id null)
/// since there's nothing left to re-add, and tells the user if that
/// happened.
class RepeatOrderButton extends ConsumerStatefulWidget {
  const RepeatOrderButton({super.key, required this.orderId, required this.filled});

  final String orderId;
  final bool filled;

  @override
  ConsumerState<RepeatOrderButton> createState() => _RepeatOrderButtonState();
}

class _RepeatOrderButtonState extends ConsumerState<RepeatOrderButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final lines = await ref.read(ordersRepositoryProvider).fetchOrderItems(widget.orderId);
      final quantities = <String, int>{};
      var skipped = 0;
      for (final line in lines) {
        if (line.itemId == null) {
          skipped++;
          continue;
        }
        quantities[line.itemId!] = line.quantity;
      }
      ref.read(cartProvider.notifier).setAll(quantities);

      if (!mounted) return;
      if (skipped > 0) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '$skipped item${skipped == 1 ? '' : 's'} from this order are no longer available and were skipped.',
              ),
            ),
          );
      }
      context.go(AppRoutes.cart);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(mapErrorToAppException(error).message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: widget.filled ? AppColors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: widget.filled ? null : Border.all(color: AppColors.secondary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _handleTap,
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.filled ? AppColors.ctaText : AppColors.secondary,
                    ),
                  )
                : Text(
                    'Repeat Order',
                    style: TextStyle(
                      color: widget.filled ? AppColors.ctaText : AppColors.secondary,
                      fontSize: 14,
                      fontFamily: AppTextStyles.urbanistFontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
