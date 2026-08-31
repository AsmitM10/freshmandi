import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import 'order_share_card.dart';

/// "Share as Image" — renders [OrderShareCard] off-screen and shares the
/// resulting PNG through the native share sheet. One tap, no intermediate
/// menu, per the approved "extremely simple, no unnecessary navigation"
/// requirement.
Future<void> shareOrderAsImage(BuildContext context, Order order) async {
  try {
    final controller = ScreenshotController();
    final bytes = await controller.captureFromWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 3),
        child: OrderShareCard(order: order),
      ),
      pixelRatio: 3,
    );

    final dir = await getTemporaryDirectory();
    final file = await File('${dir.path}/${order.id}.png').writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'FreshMandi order ${order.id}');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate image: $e')));
    }
  }
}

/// "Share as PDF" — builds a one-page PDF from the same order data and
/// shares it directly through `printing`'s share sheet (which also offers
/// Save to Files / Print on most platforms).
Future<void> shareOrderAsPdf(BuildContext context, Order order) async {
  try {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pwContext) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 28,
                  height: 28,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#4C6C46'), borderRadius: pw.BorderRadius.circular(6)),
                  child: pw.Text('FM', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FreshMandi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text('Business Console', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ORDER ID', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(order.id, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  ],
                ),
                pw.Text(order.status.label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Customer: ${order.customerName}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Date: ${formatDateTime(order.placed)}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 14),
            pw.Divider(),
            pw.Table(
              columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2)},
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                ]),
                for (final item in order.items)
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Text('${item.qty} ${item.unit}', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Text(formatInr(item.amount), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                  ]),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text(formatInr(order.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: '${order.id}.pdf');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate PDF: $e')));
    }
  }
}
