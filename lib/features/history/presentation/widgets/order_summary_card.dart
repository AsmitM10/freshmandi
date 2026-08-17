import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/domain/order_history_entry.dart';

/// The green-header/cream-body order summary card — shared by the History
/// list (View Details + Repeat Order) and the Invoice detail screen (just
/// Repeat Order), which differ only in which actions sit at the bottom.
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Field(label: 'ORDER NO.'),
                              Text(entry.orderNumber, style: _valueStyle),
                              const SizedBox(height: 16),
                              const _Field(label: 'ITEMS'),
                              Text('${entry.itemCount}', style: _valueStyle),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: VerticalDivider(color: AppColors.cardBorder, width: 1),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const _Field(label: 'DELIVERY ON', alignEnd: true),
                              Text(
                                entry.deliveryDate != null
                                    ? DateFormat('dd/MM/yyyy').format(entry.deliveryDate!)
                                    : '—',
                                textAlign: TextAlign.right,
                                style: _valueStyle,
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: entry.hasInvoice ? 'TOTAL AMT.' : 'INVOICE',
                                alignEnd: true,
                              ),
                              Text(
                                entry.hasInvoice
                                    ? '₹${NumberFormat('#,##0').format(entry.invoiceTotal)}'
                                    : 'Awaiting invoice',
                                textAlign: TextAlign.right,
                                style: entry.hasInvoice
                                    ? _valueStyle.copyWith(color: AppColors.invoiceGreen)
                                    : _valueStyle.copyWith(
                                        fontSize: 14,
                                        color: AppColors.placeholder,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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

const _valueStyle = TextStyle(
  color: Colors.black,
  fontSize: 16,
  fontFamily: AppTextStyles.urbanistFontFamily,
  fontWeight: FontWeight.w600,
);

class _Field extends StatelessWidget {
  const _Field({required this.label, this.alignEnd = false});

  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: AppColors.labelGray,
        fontSize: 12,
        fontFamily: AppTextStyles.fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.48,
      ),
    );
  }
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
      color = AppColors.accentGreen;
    } else {
      text = 'Unpaid';
      color = AppColors.accentYellow;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(50)),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 13,
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Shared "View Details" / "Repeat Order" pill-button chrome.
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
        color: filled ? AppColors.secondary : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
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
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
