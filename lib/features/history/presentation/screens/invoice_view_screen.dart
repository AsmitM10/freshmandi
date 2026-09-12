import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/save_image.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../providers/business_settings_providers.dart';
import '../widgets/invoice_document.dart';

/// The full styled invoice document (same one [OrderDetailScreen]'s
/// Download button rasterizes) shown live on screen, sized to the actual
/// device width rather than the fixed document width used for
/// downloads/shares. Reached from an "Order accepted" notification's View
/// Invoice action.
class InvoiceViewScreen extends ConsumerStatefulWidget {
  const InvoiceViewScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends ConsumerState<InvoiceViewScreen> {
  final _captureKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isDownloading = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Nothing to download yet.');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await saveImageBytes(bytes, 'freshmandi_invoice_${widget.orderId}');
      if (mounted) _showMessage(l10n.invoiceDownloadSuccess);
    } catch (error) {
      if (mounted) _showMessage(l10n.invoiceDownloadFailure);
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
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(orderSummaryProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));
    final restaurantAsync = ref.watch(currentRestaurantProvider);
    final businessAsync = ref.watch(businessSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              title: l10n.invoiceTitle,
              onBack: () => context.pop(),
              onDownload: _isDownloading ? null : _handleDownload,
              isDownloading: _isDownloading,
            ),
            Expanded(
              child: summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, _) => EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: l10n.invoiceLoadError,
                  action: TextButton(
                    onPressed: () => ref.refresh(orderSummaryProvider(widget.orderId)),
                    child: Text(l10n.retry),
                  ),
                ),
                data: (summary) {
                  final isAccepted = summary.hasInvoice && summary.invoiceTotal != null;
                  if (!isAccepted) {
                    return EmptyState(icon: Icons.hourglass_top_outlined, message: l10n.invoiceWaitingBody);
                  }

                  final lines = itemsAsync.valueOrNull;
                  final restaurant = restaurantAsync.valueOrNull;
                  final business = businessAsync.valueOrNull;
                  if (lines == null || restaurant == null || business == null) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: LayoutBuilder(
                      builder: (context, constraints) => RepaintBoundary(
                        key: _captureKey,
                        child: InvoiceDocument(
                          entry: summary,
                          lines: lines,
                          restaurant: restaurant,
                          business: business,
                          width: constraints.maxWidth,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack, required this.onDownload, required this.isDownloading});

  final String title;
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
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
