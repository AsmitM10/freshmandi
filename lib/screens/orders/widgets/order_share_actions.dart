import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../../features/history/domain/business_settings.dart';
import '../../../features/history/presentation/providers/business_settings_providers.dart';
import '../../../models/order.dart';
import 'order_share_card.dart';

/// "Share as Image" — renders [OrderShareCard] off-screen and shares the
/// resulting PNG through the native share sheet. One tap, no intermediate
/// menu, per the approved "extremely simple, no unnecessary navigation"
/// requirement.
Future<void> shareOrderAsImage(BuildContext context, WidgetRef ref, Order order) async {
  try {
    final business = await _tryFetchBusiness(ref);
    final controller = ScreenshotController();
    final bytes = await controller.captureFromWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 3),
        child: OrderShareCard(order: order, business: business),
      ),
      pixelRatio: 3,
    );

    // Built straight from the in-memory bytes, not a real file path —
    // path_provider (needed to resolve a real temp-file path) has no web
    // implementation in this project, which made every "Share as Image"
    // fail with a MissingPluginException there. XFile.fromData works on
    // every platform: share_plus's web implementation shares bytes
    // directly (falling back to a browser download automatically), and
    // its native implementations still resolve their own temp path
    // internally when given a pathless XFile.
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: '${order.orderNumber}.png', mimeType: 'image/png')],
        text: 'FreshMandi order ${order.orderNumber}',
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate image: $e')));
    }
  }
}

/// "Share as PDF" — builds a one-page PDF mirroring [OrderShareCard]'s own
/// hierarchy (business identity, invoice details, items with no rate, a
/// single total, a payment QR) and shares it through `printing`'s share
/// sheet (which also offers Save to Files / Print on most platforms).
Future<void> shareOrderAsPdf(BuildContext context, WidgetRef ref, Order order) async {
  try {
    final business = await _tryFetchBusiness(ref);
    final qrImage = business?.upiId != null ? await _buildQrImage(_upiUri(business!, order)) : null;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pwContext) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 30,
                  height: 30,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#4C6C46'), borderRadius: pw.BorderRadius.circular(7)),
                  child: pw.Text('FM', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(business?.businessName ?? 'FreshMandi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15)),
                      if (business != null) ...[
                        pw.Text(business.address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        pw.Text(business.phoneNumber, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ] else
                        pw.Text('Business Console', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('INVOICE DETAILS', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _pdfKv('Order No.', order.orderNumber),
            if (order.invoiceNumber != null) _pdfKv('Invoice No.', order.invoiceNumber!),
            _pdfKv('Customer', order.customerName),
            if (order.customerPhone != null) _pdfKv('Phone', order.customerPhone!),
            _pdfKv('Date', formatDateTime(order.placed)),
            _pdfKv('Status', order.status.label),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text('ITEMS', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            for (final item in order.items)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(item.name, style: const pw.TextStyle(fontSize: 9.5)),
                    pw.Text('${item.qty} ${item.unit}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
                  ],
                ),
              ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F3F7F0'), borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL AMOUNT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(formatInr(order.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColor.fromHex('#3E5637'))),
                ],
              ),
            ),
            if (qrImage != null && business?.upiId != null) ...[
              pw.SizedBox(height: 14),
              pw.Row(
                children: [
                  pw.Image(qrImage, width: 70, height: 70),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SCAN TO PAY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#3E5637'))),
                      pw.SizedBox(height: 2),
                      pw.Text(business!.upiId!, style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: '${order.orderNumber}.pdf');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate PDF: $e')));
    }
  }
}

pw.Widget _pdfKv(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 70, child: pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
          pw.Text(value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

/// Business settings are informational polish on this document, not a
/// requirement — a failed/slow fetch falls back to null (OrderShareCard
/// and the PDF builder above both already render a sensible default in
/// that case) rather than blocking the whole share action on it.
Future<BusinessSettings?> _tryFetchBusiness(WidgetRef ref) async {
  try {
    return await ref.read(businessSettingsProvider.future);
  } catch (_) {
    return null;
  }
}

String _upiUri(BusinessSettings business, Order order) =>
    'upi://pay?pa=${business.upiId}&pn=${Uri.encodeComponent(business.businessName)}'
    '&am=${order.total.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('FreshMandi ${order.orderNumber}')}';

Future<pw.MemoryImage> _buildQrImage(String data) async {
  final painter = QrPainter(data: data, version: QrVersions.auto, gapless: true);
  final imageData = await painter.toImageData(300);
  return pw.MemoryImage(imageData!.buffer.asUint8List());
}
