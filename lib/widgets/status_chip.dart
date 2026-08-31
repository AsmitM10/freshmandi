import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/order.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusChip({super.key, required this.label, required this.color, required this.background});

  factory StatusChip.orderStatus(OrderStatus status) {
    return status == OrderStatus.pending
        ? const StatusChip(label: 'Pending', color: AppColors.warn600, background: AppColors.warn100)
        : const StatusChip(label: 'Confirmed', color: AppColors.ok600, background: AppColors.ok100);
  }

  factory StatusChip.paymentStatus(PaymentStatus status) {
    return status == PaymentStatus.paid
        ? const StatusChip(label: 'Paid', color: AppColors.ok600, background: AppColors.ok100)
        : const StatusChip(label: 'Pending', color: AppColors.warn600, background: AppColors.warn100);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
