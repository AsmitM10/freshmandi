import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/utils/save_image.dart';
import '../../../../core/utils/share_image.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../domain/admin_transaction.dart';
import '../../domain/sale_line_item.dart';
import '../widgets/admin_receipt_document.dart';

/// Renders [transaction] (and [items], when the caller has them) as an
/// [AdminReceiptDocument], rasterizes it off an Overlay, and shares it as a
/// real image — shared by every place that offers "share this receipt" (the
/// Home dashboard's transaction cards, the Sale Invoice screen). Kept as one
/// helper so this delicate technique (RepaintBoundary + double endOfFrame +
/// a share timeout that falls back to a plain download) only lives in one
/// place.
Future<void> shareAdminReceipt(
  BuildContext context,
  AdminTransaction transaction, {
  List<SaleLineItem>? items,
}) async {
  OverlayEntry? entry;
  try {
    final overlayState = Overlay.of(context, rootOverlay: true);
    final captureKey = GlobalKey();
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: Material(
          child: RepaintBoundary(
            key: captureKey,
            child: AdminReceiptDocument(transaction: transaction, items: items),
          ),
        ),
      ),
    );
    overlayState.insert(entry);

    // Let it actually paint before reading the RenderObject — same
    // technique as the restaurant-side invoice download, the only one
    // proven reliable on Flutter Web (see OrderDetailScreen).
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Nothing to share yet.');

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    entry.remove();
    entry = null;

    final fileName = 'freshmandi_transaction_${transaction.orderId}';
    try {
      // navigator.share() on desktop web can hang indefinitely rather than
      // resolving/rejecting cleanly — a timeout guards against that so this
      // never gets stuck, falling back to the same plain download mechanism
      // the customer invoice download already relies on.
      await shareImageBytes(
        bytes,
        fileName,
        text: 'Transaction receipt from FreshMandi',
      ).timeout(const Duration(seconds: 6));
      if (context.mounted) showAppSnackBar(context, 'Receipt shared.');
    } on TimeoutException {
      await saveImageBytes(bytes, fileName);
      if (context.mounted) showAppSnackBar(context, 'Receipt downloaded.');
    }
  } catch (error, stack) {
    debugPrint('Admin receipt share failed: $error\n$stack');
    if (context.mounted) {
      showAppSnackBar(context, 'Could not share. Please try again.');
    }
  } finally {
    entry?.remove();
  }
}
