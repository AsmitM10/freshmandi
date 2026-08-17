import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../history/presentation/widgets/order_items_card.dart';
import '../../../history/presentation/widgets/order_summary_card.dart';
import '../../../history/presentation/widgets/repeat_order_button.dart';
import '../providers/orders_providers.dart';

/// Shown once, right after Place Order succeeds — the same summary +
/// item-list cards as History/Invoice (this order will show up there too,
/// under Pending Invoice until a wholesaler generates its invoice), with a
/// success badge and copy on top confirming the submission went through.
class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(orderSummaryProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.go(AppRoutes.history),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: AppColors.primaryText,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: summaryAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: "Order placed, but couldn't load its details. Check History instead.",
                  action: TextButton(
                    onPressed: () => context.go(AppRoutes.history),
                    child: const Text('Go to History'),
                  ),
                ),
                data: (summary) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    const _SuccessBadge(),
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      'Order Placed Successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 20,
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _FreshProductBadge(),
                    const SizedBox(height: AppSpacing.xl),
                    OrderSummaryCard(
                      entry: summary,
                      actions: Row(
                        children: [
                          Expanded(
                            child: OrderActionButton(
                              label: 'View Details',
                              filled: false,
                              onPressed: () => context.push('/history/order/$orderId'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: RepeatOrderButton(orderId: orderId, filled: true)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    itemsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                      error: (error, _) => const SizedBox.shrink(),
                      data: (lines) => lines.isEmpty ? const SizedBox.shrink() : OrderItemsCard(lines: lines),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Concentric-circle checkmark badge with a scatter of decorative dots
/// behind it. Purely decorative — ported close to the Figma export's exact
/// dot positions/colors since there's no interactive layout concern here,
/// just static confetti.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  // Two concentric rings of dots at evenly spaced angles (offset from each
  // other), placed by real pixel radius around the box's center rather
  // than the Figma export's raw absolute coordinates (which assumed its
  // fixed 375px frame) or plain fractional Alignment (which stretches a
  // circle into a wide ellipse on a short, wide box). A true pixel-radius
  // ring stays evenly spaced regardless of the box's aspect ratio.
  static const _innerRadius = 48.0;
  static const _outerRadius = 68.0;
  static const _innerCount = 8;
  static const _outerCount = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: SizedBox(
          width: 170,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < _innerCount; i++)
                _ScatterDot(
                  angle: (2 * math.pi * i) / _innerCount,
                  radius: _innerRadius,
                  color: const Color(0x7F4ADA55),
                ),
              for (var i = 0; i < _outerCount; i++)
                _ScatterDot(
                  angle: (2 * math.pi * i) / _outerCount + (math.pi / _outerCount),
                  radius: _outerRadius,
                  color: const Color(0xFFA4FCA8),
                ),
              Container(
                width: 90,
                height: 90,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0x4C4ADA55), shape: BoxShape.circle),
                child: Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Color(0x754ADA55), shape: BoxShape.circle),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFF4ADA55), shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 26),
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

class _ScatterDot extends StatelessWidget {
  const _ScatterDot({required this.angle, required this.radius, required this.color});

  final double angle;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
      child: Transform.rotate(
        angle: -0.78,
        child: Container(width: 8, height: 8, color: color),
      ),
    );
  }
}

/// "Fresh product on its way to you!" pill. The Figma export's leaf icon
/// wasn't provided as a real asset (unlike the checkmark/mic SVGs
/// elsewhere) — `Icons.eco` stands in for it rather than inventing a fake
/// vector; swap in the real SVG if/when it's provided.
class _FreshProductBadge extends StatelessWidget {
  const _FreshProductBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x334A8754),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco_outlined, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              'Fresh product on its way to you!',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
