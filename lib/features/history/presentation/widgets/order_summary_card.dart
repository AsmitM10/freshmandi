import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/order_history_entry.dart';

/// The green-header/cream-body order summary card — shared by the History
/// list (View Details + Repeat Order/Pay Now), the Invoice detail screen,
/// and the post-Place-Order success screen. Three centered fields (ORDER
/// NO. / PRICE / ITEMS, "PRICE" being the invoice total — never a
/// per-item price) separated by dashed dividers; delivery date isn't part
/// of this card design.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.entry, required this.actions});

  final OrderHistoryEntry entry;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(entry.createdAt),
                        style: const TextStyle(
                          color: AppColors.ctaText,
                          fontSize: 16,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(entry.createdAt),
                        style: const TextStyle(
                          color: AppColors.ctaText,
                          fontSize: 14,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(entry: entry),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'ORDER NO.',
                            value: entry.orderNumber,
                          ),
                        ),
                        const _DashedDivider(axis: Axis.vertical),
                        Expanded(
                          child: _Field(
                            label: 'PRICE',
                            value: entry.hasInvoice
                                ? '₹${NumberFormat('#,##0').format(entry.invoiceTotal)}'
                                : '-',
                            valueColor: entry.hasInvoice ? AppColors.invoiceGreen : Colors.black,
                            valueWeight: entry.hasInvoice ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        const _DashedDivider(axis: Axis.vertical),
                        Expanded(
                          child: _Field(label: 'ITEMS', value: '${entry.itemCount}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _DashedDivider(axis: Axis.horizontal),
                  const SizedBox(height: 16),
                  actions,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.valueColor = Colors.black,
    this.valueWeight = FontWeight.w500,
  });

  final String label;
  final String value;
  final Color valueColor;
  final FontWeight valueWeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.labelGray,
            fontSize: 12,
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.48,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontFamily: AppTextStyles.urbanistFontFamily,
            fontWeight: valueWeight,
          ),
        ),
      ],
    );
  }
}

/// Dashed divider — Flutter has no built-in dashed border/line, and this
/// design calls for one both vertically (between the three fields) and
/// horizontally (above the action buttons).
class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.axis});

  final Axis axis;

  static const _dashLength = 4.0;
  static const _gapLength = 3.0;
  static const _color = Color(0x4D000000); // black @ 30%

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      return SizedBox(
        width: 1,
        child: CustomPaint(painter: _DashPainter(axis: axis)),
      );
    }
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashPainter(axis: axis)),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.axis});

  final Axis axis;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _DashedDivider._color
      ..strokeWidth = 1;
    final total = axis == Axis.vertical ? size.height : size.width;
    var current = 0.0;
    while (current < total) {
      final end = (current + _DashedDivider._dashLength).clamp(0, total);
      final start = axis == Axis.vertical ? Offset(0, current) : Offset(current, 0);
      final stop = axis == Axis.vertical ? Offset(0, end.toDouble()) : Offset(end.toDouble(), 0);
      canvas.drawLine(start, stop, paint);
      current += _DashedDivider._dashLength + _DashedDivider._gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.entry});

  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    if (!entry.hasInvoice) {
      text = 'Pending';
      color = AppColors.accentYellow;
    } else if (entry.isPaid) {
      text = 'Paid';
      color = AppColors.statusPaidGreen;
    } else {
      text = 'Unpaid';
      color = AppColors.accentYellow;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(50)),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 13,
          fontFamily: AppTextStyles.urbanistFontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Shared "View Details" / "Repeat Order" / "Pay Now" pill-button chrome —
/// fully rounded, filled variant solid navy, unfilled variant plain text
/// (no border), matching the pill-button order-card redesign.
class OrderActionButton extends StatelessWidget {
  const OrderActionButton({required this.label, required this.filled, this.onPressed, super.key});

  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: filled ? AppColors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: filled ? null : Border.all(color: AppColors.secondary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: filled ? AppColors.ctaText : AppColors.secondary,
                fontSize: 14,
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
