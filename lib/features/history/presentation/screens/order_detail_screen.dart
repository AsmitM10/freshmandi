import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/save_image.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_primary_action.dart';
import '../widgets/order_summary_card.dart';

/// Invoice / order detail screen — the same order summary card as the
/// History list (date/status/order no./delivery/total, but with only the
/// Repeat Order action since "View Details" is redundant here) plus the
/// full item list. Never shows a per-item price, per the no-item-price
/// rule — only quantity/unit, snapshotted at order time.
///
/// Download captures exactly what's shown here (summary + item list) as a
/// PNG saved to the device gallery. It does not attempt the fuller
/// formatted-bill layout (wholesaler business details, a separate invoice
/// number, restaurant billing address, UPI QR) sometimes seen in printed
/// invoices — none of that data exists in this schema yet (no
/// wholesaler/vendor table, no invoice-number scheme, no restaurant
/// address fields), so it isn't invented here.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _captureKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Nothing to download yet.');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      await saveImageBytes(bytes, 'freshmandi_invoice_${widget.orderId}');
      if (mounted) _showMessage('Invoice saved.');
    } catch (error) {
      if (mounted) _showMessage("Couldn't save the invoice: $error");
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
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
              onDownload: summaryAsync.hasValue ? _handleDownload : null,
              isDownloading: _isDownloading,
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
                data: (summary) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    AppSpacing.bottomNavHeight + AppSpacing.base,
                  ),
                  child: RepaintBoundary(
                    key: _captureKey,
                    child: Container(
                      color: AppColors.backgroundHome,
                      padding: const EdgeInsets.all(1),
                      child: Column(
                        children: [
                          OrderSummaryCard(
                            entry: summary,
                            actions: OrderPrimaryAction(entry: summary),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          itemsAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
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
  const _Header({required this.onBack, required this.onDownload, required this.isDownloading});

  final VoidCallback onBack;
  final VoidCallback? onDownload;
  final bool isDownloading;

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
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onDownload,
                child: Center(
                  child: isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText),
                        )
                      : SvgPicture.asset(
                          'assets/icons/icon_download.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            onDownload == null ? AppColors.placeholder : AppColors.primaryText,
                            BlendMode.srcIn,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
