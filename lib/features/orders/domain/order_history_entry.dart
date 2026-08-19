/// One row of the History list — mirrors `public.order_history` (a view
/// joining orders + invoices + a derived item count so the screen needs
/// exactly one query per page, not N+1). No price ever appears here
/// except the invoice's own final total, and only once an invoice has
/// actually been generated (`hasInvoice`) — see the no-item-price rule.
class OrderHistoryEntry {
  const OrderHistoryEntry({
    required this.orderId,
    required this.orderNumber,
    required this.orderStatus,
    required this.createdAt,
    required this.deliveryDate,
    required this.itemCount,
    required this.hasInvoice,
    this.invoiceTotal,
    this.paymentStatus,
    this.invoiceNumber,
  });

  factory OrderHistoryEntry.fromMap(Map<String, dynamic> map) => OrderHistoryEntry(
    orderId: map['order_id'] as String,
    orderNumber: map['order_number'] as String,
    orderStatus: map['order_status'] as String,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    deliveryDate: map['delivery_date'] != null
        ? DateTime.parse(map['delivery_date'] as String)
        : null,
    itemCount: map['item_count'] as int,
    hasInvoice: map['has_invoice'] as bool,
    invoiceTotal: (map['invoice_total'] as num?)?.toDouble(),
    paymentStatus: map['payment_status'] as String?,
    invoiceNumber: map['invoice_number'] as String?,
  );

  final String orderId;
  final String orderNumber;
  final String orderStatus;
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final int itemCount;
  final bool hasInvoice;
  final double? invoiceTotal;
  final String? paymentStatus;

  /// Stable per-order id assigned once an invoice is generated (see the
  /// invoice_number migration) — null exactly when [hasInvoice] is false.
  final String? invoiceNumber;

  bool get isPaid => paymentStatus == 'paid';
}
