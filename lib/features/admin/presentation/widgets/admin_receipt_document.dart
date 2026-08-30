import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/admin_transaction.dart';
import '../../domain/sale_line_item.dart';

/// Standalone, capturable receipt for a single admin transaction — mirrors
/// the restaurant side's InvoiceDocument (own widget, independent of any
/// on-screen card, rasterized via RepaintBoundary, never a screenshot).
/// Layout follows the reference mock's structure closely (plain white
/// card, name+phone top-left, brand top-right, centered title, boxed
/// amounts section) — FreshMandi-branded throughout, not a copy of that
/// reference's own third-party logo or copy.
class AdminReceiptDocument extends StatelessWidget {
  const AdminReceiptDocument({
    super.key,
    required this.transaction,
    this.items,
  });

  final AdminTransaction transaction;

  /// The items billed on this sale — shown as their own section between
  /// "Received from" and the Amounts box, same fields as the on-screen
  /// Billed Items card. Null/empty when the caller has no item list handy
  /// (e.g. sharing straight from the Home dashboard's transaction list,
  /// which doesn't fetch items), in which case that section is skipped.
  final List<SaleLineItem>? items;

  static const _brandGreen = Color(0xFF1B5E20);
  static const _brandBlue = Color(0xFF355C7D);
  static const _borderGray = Color(0xFFE8E6DF);
  static const _ink = Color(0xFF1F2A22);
  static const _muted = Color(0xFF9AA09B);
  static const _documentWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final receivedAmount = transaction.isPaid ? transaction.invoiceTotal : 0;

    return Material(
      color: Colors.white,
      child: Container(
        width: _documentWidth,
        padding: const EdgeInsets.all(28),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.restaurantName,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.restaurantPhone,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'GENERATED ON',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Fresh',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(
                            text: 'Mandi',
                            style: TextStyle(
                              color: _brandGreen,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 36),
            Center(
              child: Text(
                'Transaction Receipt',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 26,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Received from:',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        transaction.restaurantName,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        transaction.restaurantPhone,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Receipt No.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      transaction.invoiceNumber ?? '-',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Date: ${DateFormat('dd MMM, yyyy').format(transaction.createdAt)}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (items != null && items!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _ItemsSection(items: items!),
            ],
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Amounts',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AmountRow(
                    label: 'Received Amount',
                    amount: receivedAmount.toDouble(),
                  ),
                  const SizedBox(height: 8),
                  _AmountRow(
                    label: 'Total Amount',
                    amount: transaction.invoiceTotal,
                    color: _brandBlue,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});

  final List<SaleLineItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminReceiptDocument._borderGray),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: AdminReceiptDocument._brandGreen,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Billed Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: i == 0
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AdminReceiptDocument._borderGray,
                        ),
                      ),
                    ),
              child: Row(
                children: [
                  Text(
                    '#${i + 1}  ',
                    style: const TextStyle(
                      color: AdminReceiptDocument._ink,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].itemName,
                          style: const TextStyle(
                            color: AdminReceiptDocument._ink,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Item Subtotal',
                          style: TextStyle(
                            color: AdminReceiptDocument._muted,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${NumberFormat('#,##0').format(items[i].subtotal)}',
                        style: const TextStyle(
                          color: AdminReceiptDocument._ink,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${items[i].rate.toStringAsFixed(0)} * ${items[i].quantity} = ${items[i].subtotal.toStringAsFixed(0)}₹',
                        style: const TextStyle(
                          color: AdminReceiptDocument._muted,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.color,
    this.bold = false,
  });

  final String label;
  final double amount;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AdminReceiptDocument._ink;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? AdminReceiptDocument._muted,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        Text(
          '₹${NumberFormat('#,##0.00').format(amount)}',
          style: TextStyle(
            color: resolvedColor,
            fontSize: 15,
            fontFamily: 'Poppins',
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
