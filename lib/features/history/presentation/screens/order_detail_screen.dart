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
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../orders/domain/order_history_entry.dart';
import '../../../orders/domain/order_line_item.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../providers/business_settings_providers.dart';
import '../widgets/invoice_document.dart';
import '../widgets/order_items_card.dart';
import '../widgets/order_primary_action.dart';
import '../widgets/order_summary_card.dart';

/// Invoice / order detail screen — the same order summary card as the
/// History list (date/status/order no./delivery/total, but with only the
/// Repeat Order action since "View Details" is redundant here) plus the
/// full item list. Never shows a per-item price, per the no-item-price
/// rule — only quantity/unit, snapshotted at order time.
///
/// "Accepted" in this app's business sense = `entry.hasInvoice &&
/// entry.invoiceTotal != null` (a row exists in `invoices`, which only a
/// service-role/admin action can create) — there's no separate
/// `orders.status == 'accepted'` value; the invoices table's mere
/// presence *is* the acceptance signal, and it's what already gates the
/// PRICE field everywhere else in this app. A pending order (no invoice
/// yet) shows a "waiting for confirmation" notice and can never download
/// an invoice, even if triggered some other way — [_handleDownload]
/// re-validates this itself rather than trusting that the button being
/// enabled was the only guard.
///
/// Download renders a standalone [InvoiceDocument] — briefly, into the
/// app's real root [Overlay] (see [_handleDownload]) — and rasterizes
/// *that*, not a screenshot of this screen's own cards.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isDownloading = false;

  bool _isAccepted(OrderHistoryEntry summary) => summary.hasInvoice && summary.invoiceTotal != null;

  Future<void> _handleDownload(OrderHistoryEntry summary, List<OrderLineItem> lines) async {
    if (_isDownloading) return;
    final l10n = AppLocalizations.of(context);

    // Re-validated here independently of the button's enabled state — see
    // the class doc comment. A pending order can never produce a PNG.
    if (!_isAccepted(summary)) {
      _showMessage(l10n.invoiceNotAvailableYet);
      return;
    }

    setState(() => _isDownloading = true);
    OverlayEntry? entry;
    try {
      final restaurant = await ref.read(currentRestaurantProvider.future);
      final business = await ref.read(businessSettingsProvider.future);
      if (restaurant == null) throw Exception('Could not load your account.');
      if (!mounted) return;

      // Rendering the document off-screen (translated far outside the
      // viewport, or genuinely on-screen but occluded by opaque content)
      // both produced a blank `toImage()` capture on Flutter web — the
      // engine appears to skip rasterizing a layer it can determine will
      // never actually be composited into the visible frame, regardless
      // of the framework-level RepaintBoundary. Inserting into the real
      // root Overlay (the same layer dialogs/tooltips use) is the one
      // technique guaranteed to be treated as genuine, paintable content
      // on every platform — it's visible for a couple of frames (a brief,
      // expected flash, same as any "generating..." export flow), then
      // removed the instant we're done capturing it.
      final overlayState = Overlay.of(context, rootOverlay: true);
      final captureKey = GlobalKey();
      entry = OverlayEntry(
        builder: (context) => Positioned(
          left: 0,
          top: 0,
          child: Material(
            child: RepaintBoundary(
              key: captureKey,
              child: InvoiceDocument(entry: summary, lines: lines, restaurant: restaurant, business: business),
            ),
          ),
        ),
      );
      overlayState.insert(entry);

      // Let it actually paint before reading the RenderObject.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary = captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Nothing to download yet.');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      entry.remove();
      entry = null;

      await saveImageBytes(bytes, 'freshmandi_invoice_${widget.orderId}');
      if (mounted) _showMessage(l10n.invoiceDownloadSuccess);
    } catch (error, stack) {
      debugPrint('Invoice download failed: $error\n$stack');
      if (mounted) _showMessage(l10n.invoiceDownloadFailure);
    } finally {
      entry?.remove();
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
    final l10n = AppLocalizations.of(context);
    final orderId = widget.orderId;
    final summaryAsync = ref.watch(orderSummaryProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    final summary = summaryAsync.valueOrNull;
    final lines = itemsAsync.valueOrNull;
    final canDownload = summary != null && lines != null && _isAccepted(summary);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              title: l10n.invoiceTitle,
              onBack: () => context.pop(),
              onDownload: summary == null ? null : () => _handleDownload(summary, lines ?? const []),
              isDownloading: _isDownloading,
              isEnabled: canDownload,
            ),
            Expanded(
              child: summaryAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: l10n.invoiceLoadError,
                  action: TextButton(
                    onPressed: () => ref.refresh(orderSummaryProvider(orderId)),
                    child: Text(l10n.retry),
                  ),
                ),
                data: (summary) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomNavHeight + AppSpacing.base),
                  child: Column(
                    children: [
                      OrderSummaryCard(entry: summary, actions: OrderPrimaryAction(entry: summary)),
                      if (!_isAccepted(summary)) ...[
                        const SizedBox(height: AppSpacing.base),
                        _PendingNotice(title: l10n.invoiceWaitingTitle, body: l10n.invoiceWaitingBody),
                      ],
                      const SizedBox(height: AppSpacing.base),
                      itemsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                        error: (error, _) => EmptyState(
                          icon: Icons.wifi_off_outlined,
                          message: l10n.invoiceItemsLoadError,
                          action: TextButton(
                            onPressed: () => ref.refresh(orderItemsProvider(orderId)),
                            child: Text(l10n.retry),
                          ),
                        ),
                        data: (lines) => lines.isEmpty
                            ? EmptyState(icon: Icons.receipt_long_outlined, message: l10n.invoiceNoItems)
                            : OrderItemsCard(lines: lines),
                      ),
                    ],
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

class _PendingNotice extends StatelessWidget {
  const _PendingNotice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentYellow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentYellow),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top_outlined, color: AppColors.primaryText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontFamily: AppTextStyles.urbanistFontFamily,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: AppTextStyles.devanagariFallback,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.caption.copyWith(fontFamilyFallback: AppTextStyles.devanagariFallback),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onBack,
    required this.onDownload,
    required this.isDownloading,
    required this.isEnabled,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onDownload;
  final bool isDownloading;

  /// Whether the order is accepted (has a real invoice) — purely a visual
  /// affordance (muted vs. active icon color). `onDownload` stays tappable
  /// either way so a pending order still gets the "will be available
  /// after confirmation" message instead of doing nothing.
  final bool isEnabled;

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
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                fontFamilyFallback: AppTextStyles.devanagariFallback,
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
                            onDownload == null || !isEnabled ? AppColors.placeholder : AppColors.primaryText,
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
