import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/repeat_order_button.dart';

/// Invoice / order detail screen — the same order summary card as the
/// History list (date/status/order no./delivery/total, but with only the
/// Repeat Order action since "View Details" is redundant here) plus the
/// full item list. Never shows a per-item price, per the no-item-price
/// rule — only quantity/unit, snapshotted at order time.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(orderSummaryProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              onBack: () => context.pop(),
              onRetry: () {
                ref.invalidate(orderSummaryProvider(orderId));
                ref.invalidate(orderItemsProvider(orderId));
              },
            ),
            Expanded(
              child: summaryAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: "Couldn't load this order. Check your connection and try again.",
                  action: TextButton(
                    onPressed: () => ref.refresh(orderSummaryProvider(orderId)),
                    child: const Text('Retry'),
                  ),
                ),
                data: (summary) => ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    AppSpacing.bottomNavHeight + AppSpacing.base,
                  ),
                  children: [
                    OrderSummaryCard(
                      entry: summary,
                      actions: RepeatOrderButton(orderId: orderId, filled: true),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    itemsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                      error: (error, _) => EmptyState(
                        icon: Icons.wifi_off_outlined,
                        message: "Couldn't load this order's items.",
                        action: TextButton(
                          onPressed: () => ref.refresh(orderItemsProvider(orderId)),
                          child: const Text('Retry'),
                        ),
                      ),
                      data: (lines) => lines.isEmpty
                          ? const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              message: 'No items found for this order.',
                            )
                          : OrderItemsCard(lines: lines),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

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
              'Invoice',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

