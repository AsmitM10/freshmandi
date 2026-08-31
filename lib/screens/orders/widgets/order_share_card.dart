import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';

/// The branded content shown on both "Share as Image" and "Share as PDF" —
/// per the approved spec: FreshMandi branding, Order ID, Customer, Items,
/// Quantity, Price, Total, Date, Order status. Built once here so both
/// export paths render identically.
class OrderShareCard extends StatelessWidget {
  final Order order;

  const OrderShareCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.brand600, borderRadius: BorderRadius.circular(8)),
                  child: const Text('FM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FreshMandi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                    Text('Business Console', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER ID', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                    Text(order.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 14),
            _kv('Customer', order.customerName),
            _kv('Date', formatDateTime(order.placed)),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            const Text('ITEMS', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('${item.emoji} ${item.name}', style: const TextStyle(fontSize: 13)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('${item.qty} ${item.unit}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(formatInr(item.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text(formatInr(order.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brand700)),
              ],
            ),
            const SizedBox(height: 18),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
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
