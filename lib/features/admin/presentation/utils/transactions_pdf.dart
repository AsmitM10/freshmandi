import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/admin_transaction.dart';

const _brandGreen = PdfColor.fromInt(0xFF4A8754);
const _ink = PdfColor.fromInt(0xFF1F2A22);
const _muted = PdfColor.fromInt(0xFF9AA09B);
const _borderGray = PdfColor.fromInt(0xFFE8E6DF);

/// Builds a printable PDF listing [transactions] for the range shown on
/// the All Transactions screen — same fields as that screen's "Billed
/// Items" card (name, date, total, balance), plus the view label and date
/// range as a header so the exported file is self-describing on its own.
Future<Uint8List> buildTransactionsPdf({
  required List<AdminTransaction> transactions,
  required DateTime from,
  required DateTime to,
  required String viewLabel,
}) async {
  final doc = pw.Document();
  final dateFormat = DateFormat('dd MMM, yyyy');

  final totalSale = transactions.fold<double>(
    0,
    (sum, t) => sum + t.invoiceTotal,
  );
  final totalBalance = transactions.fold<double>(
    0,
    (sum, t) => sum + t.balance,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'All Transactions',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.Text(
                'FreshMandi',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontStyle: pw.FontStyle.italic,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandGreen,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$viewLabel  •  ${dateFormat.format(from)} - ${dateFormat.format(to)}',
            style: const pw.TextStyle(fontSize: 11, color: _muted),
          ),
          pw.SizedBox(height: 16),
        ],
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(color: _borderGray, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.6),
            1: pw.FlexColumnWidth(2.2),
            2: pw.FlexColumnWidth(1.6),
            3: pw.FlexColumnWidth(1.3),
            4: pw.FlexColumnWidth(1.3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _brandGreen),
              children: [
                _headerCell('#'),
                _headerCell('Name'),
                _headerCell('Date'),
                _headerCell('Total', alignRight: true),
                _headerCell('Balance', alignRight: true),
              ],
            ),
            for (var i = 0; i < transactions.length; i++)
              pw.TableRow(
                children: [
                  _cell('${i + 1}'),
                  _cell(transactions[i].restaurantName),
                  _cell(dateFormat.format(transactions[i].createdAt)),
                  _cell(
                    NumberFormat('#,##0').format(transactions[i].invoiceTotal),
                    alignRight: true,
                  ),
                  _cell(
                    NumberFormat('#,##0').format(transactions[i].balance),
                    alignRight: true,
                  ),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Total Sale: ${NumberFormat('#,##0').format(totalSale)}   '
              'Total Balance: ${NumberFormat('#,##0').format(totalBalance)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _ink),
            ),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _headerCell(String text, {bool alignRight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );
}

pw.Widget _cell(String text, {bool alignRight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: const pw.TextStyle(fontSize: 10, color: _ink),
    ),
  );
}
