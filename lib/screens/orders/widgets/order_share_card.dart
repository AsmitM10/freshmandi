import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/history/domain/business_settings.dart';
import '../../../models/order.dart';

/// The branded content shown on both "Share as Image" and "Share as PDF" —
/// built once here so both export paths render identically. Hierarchy:
/// our own business identity, then invoice details, then a payment QR —
/// deliberately no per-item rate anywhere on this document (only the
/// admin-facing in-app Order Details screen shows that); the paying
/// customer only ever needs to see what's owed in total.
class OrderShareCard extends StatelessWidget {
  final Order order;
  final BusinessSettings? business;

  const OrderShareCard({super.key, required this.order, this.business});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BusinessHeader(business: business),
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVOICE DETAILS',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      _kv('Order No.', order.orderNumber),
                      if (order.invoiceNumber != null) _kv('Invoice No.', order.invoiceNumber!),
                      _kv('Customer', order.customerName),
                      if (order.customerPhone != null) _kv('Phone', order.customerPhone!),
                      _kv('Date', formatDateTime(order.placed)),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            const Text('ITEMS', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${item.emoji} ${item.name}', style: const TextStyle(fontSize: 13.5)),
                    ),
                    Text('${item.qty} ${item.unit}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.brand800)),
                  Text(formatInr(order.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.brand700)),
                ],
              ),
            ),
            if (business?.upiId != null) ...[
              const SizedBox(height: 20),
              _PaymentQr(business: business!, amount: order.total, reference: order.orderNumber),
            ],
            const SizedBox(height: 20),
            const Center(
              child: Text('Generated from FreshMandi Business Console', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontFamily: 'Poppins'),
            children: [
              TextSpan(text: '$k  ', style: const TextStyle(color: AppColors.textMuted)),
              TextSpan(text: v, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.business});

  final BusinessSettings? business;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.brand600, borderRadius: BorderRadius.circular(10)),
          child: const Text('FM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                business?.businessName ?? 'FreshMandi',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
              ),
              if (business != null) ...[
                const SizedBox(height: 3),
                Text(business!.address, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                Text(business!.phoneNumber, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ] else
                const Text('Business Console', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == OrderStatus.confirmed;
    final color = isConfirmed ? AppColors.ok600 : AppColors.warn600;
    final bg = isConfirmed ? AppColors.ok100 : AppColors.warn100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

/// UPI QR — same construction as the customer-facing invoice's payment
/// section (features/history/presentation/widgets/invoice_document.dart);
/// informational only, not tied to any automatic payment confirmation.
class _PaymentQr extends StatelessWidget {
  const _PaymentQr({required this.business, required this.amount, required this.reference});

  final BusinessSettings business;
  final double amount;
  final String reference;

  String get _upiUri =>
      'upi://pay?pa=${business.upiId}&pn=${Uri.encodeComponent(business.businessName)}'
      '&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('FreshMandi $reference')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          QrImageView(data: _upiUri, size: 88, backgroundColor: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SCAN TO PAY', style: TextStyle(fontSize: 10.5, color: AppColors.brand700, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(business.upiId!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
