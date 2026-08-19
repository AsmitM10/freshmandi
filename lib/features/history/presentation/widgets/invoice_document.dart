import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../auth/domain/restaurant_account.dart';
import '../../../orders/domain/order_history_entry.dart';
import '../../../orders/domain/order_line_item.dart';
import '../../domain/business_settings.dart';

/// The standalone, downloadable invoice bill — an independent document
/// widget, not a capture of the mobile Invoice screen. Built to a fixed
/// invoice-oriented width (not device screen dimensions) and an unbounded
/// natural height so it can grow for long item lists without clipping;
/// [OrderDetailScreen] renders this off-screen and rasterizes it via
/// `RenderRepaintBoundary.toImage`, never a screenshot of the app UI.
///
/// Callers must only build this once the order is confirmed ACCEPTED
/// (`entry.hasInvoice && entry.invoiceTotal != null`) — this widget itself
/// doesn't re-validate that, the screen does before ever constructing it,
/// same as the "reject before generating" rule for invoice generation.
/// No per-item price ever appears here — the item table is name+quantity
/// only, and the only money figure on the whole document is the single
/// final [OrderHistoryEntry.invoiceTotal].
class InvoiceDocument extends StatelessWidget {
  const InvoiceDocument({
    super.key,
    required this.entry,
    required this.lines,
    required this.restaurant,
    required this.business,
  });

  final OrderHistoryEntry entry;
  final List<OrderLineItem> lines;
  final RestaurantAccount restaurant;
  final BusinessSettings business;

  static const _documentWidth = 686.0;
  static const _brandGreen = Color(0xFF1B5E20);
  static const _lightGreen = Color(0xFFEFF7ED);
  static const _borderGreen = Color(0xFFB7D9BA);
  static const _ink = Color(0xFF1F2A22);
  static const _muted = Color(0xFF5B6B60);

  @override
  Widget build(BuildContext context) {
    final totalQuantity = lines.fold<int>(0, (sum, line) => sum + line.quantity);

    return Material(
      color: Colors.white,
      child: Container(
        width: _documentWidth,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _brandGreen, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(),
            const SizedBox(height: 16),
            const Divider(color: _borderGreen, height: 1, thickness: 1.5),
            const SizedBox(height: 16),
            _BusinessAndOrderInfo(business: business, entry: entry),
            const SizedBox(height: 20),
            _AddressRow(restaurant: restaurant),
            const SizedBox(height: 20),
            _ItemTable(lines: lines),
            const SizedBox(height: 20),
            _TotalsRow(itemCount: lines.length, totalQuantity: totalQuantity, entry: entry),
            if (business.upiId != null) ...[
              const SizedBox(height: 20),
              _PaymentSection(business: business, entry: entry),
            ],
            const SizedBox(height: 20),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/freshmandi_logo.png', width: 44, height: 44, fit: BoxFit.contain),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Fresh',
                      style: TextStyle(
                        color: const Color(0xFF242424),
                        fontSize: 26,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Mandi',
                      style: TextStyle(
                        color: InvoiceDocument._brandGreen,
                        fontSize: 26,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Fresh Produce. Trusted Supply.',
                style: TextStyle(color: InvoiceDocument._muted, fontSize: 11, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: InvoiceDocument._brandGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'INVOICE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _BusinessAndOrderInfo extends StatelessWidget {
  const _BusinessAndOrderInfo({required this.business, required this.entry});

  final BusinessSettings business;
  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                business.businessName.toUpperCase(),
                style: const TextStyle(
                  color: InvoiceDocument._brandGreen,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _IconLine(icon: Icons.location_on_outlined, text: business.address),
              _IconLine(icon: Icons.call_outlined, text: business.phoneNumber),
              if (business.email != null) _IconLine(icon: Icons.mail_outline, text: business.email!),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _LabeledLine(
                icon: Icons.description_outlined,
                label: 'Invoice No.',
                value: entry.invoiceNumber ?? '-',
              ),
              _LabeledLine(
                icon: Icons.shopping_cart_outlined,
                label: 'Order No.',
                value: entry.orderNumber,
              ),
              _LabeledLine(
                icon: Icons.calendar_today_outlined,
                label: 'Order Date',
                value: DateFormat('dd MMM yyyy').format(entry.createdAt),
              ),
              _LabeledLine(
                icon: Icons.local_shipping_outlined,
                label: 'Delivery Date',
                value: entry.deliveryDate != null
                    ? DateFormat('dd MMM yyyy').format(entry.deliveryDate!)
                    : 'Not scheduled',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: InvoiceDocument._brandGreen),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: InvoiceDocument._ink, fontSize: 11.5, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledLine extends StatelessWidget {
  const _LabeledLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: InvoiceDocument._brandGreen),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: InvoiceDocument._muted, fontSize: 9.5, fontFamily: 'Poppins'),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: InvoiceDocument._ink,
                    fontSize: 12.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.restaurant});

  final RestaurantAccount restaurant;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AddressCard(
            icon: Icons.person_outline,
            label: 'BILL TO',
            name: restaurant.restaurantName,
            address: restaurant.billingAddress ?? 'Not set',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AddressCard(
            icon: Icons.location_on_outlined,
            label: 'DELIVERY ADDRESS',
            name: restaurant.restaurantName,
            address: restaurant.deliveryAddress ?? restaurant.billingAddress ?? 'Not set',
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.icon, required this.label, required this.name, required this.address});

  final IconData icon;
  final String label;
  final String name;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InvoiceDocument._lightGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: InvoiceDocument._brandGreen),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: InvoiceDocument._brandGreen,
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: InvoiceDocument._ink,
              fontSize: 12.5,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            address,
            style: const TextStyle(color: InvoiceDocument._muted, fontSize: 11, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}

/// Name/quantity only — never a price, never a rate, never a subtotal.
class _ItemTable extends StatelessWidget {
  const _ItemTable({required this.lines});

  final List<OrderLineItem> lines;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: InvoiceDocument._brandGreen,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Row(
              children: [
                SizedBox(width: 28, child: Text('#', style: _headerStyle)),
                Expanded(child: Text('VEGETABLE', style: _headerStyle)),
                SizedBox(width: 90, child: Text('QUANTITY', style: _headerStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          for (var i = 0; i < lines.length; i++)
            Container(
              color: i.isEven ? Colors.white : InvoiceDocument._lightGreen,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}', style: const TextStyle(color: InvoiceDocument._ink, fontSize: 12)),
                  ),
                  Expanded(
                    child: Text(
                      lines[i].itemName,
                      style: const TextStyle(
                        color: InvoiceDocument._ink,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      '${lines[i].quantity} ${lines[i].unit}'.trim(),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: InvoiceDocument._ink, fontSize: 12, fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.itemCount, required this.totalQuantity, required this.entry});

  final int itemCount;
  final int totalQuantity;
  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: InvoiceDocument._lightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: InvoiceDocument._borderGreen),
      ),
      child: Row(
        children: [
          Expanded(child: _TotalStat(icon: Icons.inventory_2_outlined, label: 'TOTAL ITEMS', value: '$itemCount')),
          Expanded(
            child: _TotalStat(icon: Icons.scale_outlined, label: 'TOTAL QUANTITY', value: '$totalQuantity Units'),
          ),
          Expanded(
            child: _TotalStat(
              icon: Icons.currency_rupee,
              label: 'TOTAL AMOUNT',
              value: '₹${NumberFormat('#,##0').format(entry.invoiceTotal)}',
              valueColor: InvoiceDocument._brandGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  const _TotalStat({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: InvoiceDocument._brandGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: InvoiceDocument._muted, fontSize: 9.5, fontFamily: 'Poppins'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? InvoiceDocument._ink,
            fontSize: 15,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Informational only — a printed QR/UPI id for offline/manual settlement.
/// It never sets `invoices.payment_status`; the app's real, server-verified
/// payment path is the in-app Pay Now button (Razorpay), unaffected by
/// this section.
class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.business, required this.entry});

  final BusinessSettings business;
  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final upiUri =
        'upi://pay?pa=${business.upiId}&pn=${Uri.encodeComponent(business.businessName)}'
        '&am=${entry.invoiceTotal?.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('FreshMandi ${entry.orderNumber}')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: InvoiceDocument._borderGreen),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              const Text(
                'SCAN QR CODE TO PAY',
                style: TextStyle(
                  color: InvoiceDocument._brandGreen,
                  fontSize: 9.5,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              QrImageView(data: upiUri, size: 96, backgroundColor: Colors.white),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'UPI ID',
                  style: TextStyle(color: InvoiceDocument._muted, fontSize: 9.5, fontFamily: 'Poppins'),
                ),
                Text(
                  business.upiId!,
                  style: const TextStyle(
                    color: InvoiceDocument._ink,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 13, color: InvoiceDocument._muted),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'This QR is for manual/offline payment reference only. Payments made '
                        'in-app via Pay Now are confirmed automatically.',
                        style: TextStyle(color: InvoiceDocument._muted, fontSize: 10, fontFamily: 'Poppins'),
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

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: InvoiceDocument._borderGreen, height: 1, thickness: 1),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 14, color: InvoiceDocument._brandGreen),
            SizedBox(width: 6),
            Text(
              'Thank you for choosing FreshMandi!',
              style: TextStyle(
                color: InvoiceDocument._brandGreen,
                fontSize: 12.5,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Fresh Produce  •  Trusted Supply  •  Smarter Procurement',
          style: TextStyle(color: InvoiceDocument._muted, fontSize: 10, fontFamily: 'Poppins'),
        ),
      ],
    );
  }
}
