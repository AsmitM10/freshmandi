/// Mirrors one row of `public.admin_order_overview` — an order that has a
/// generated invoice (the admin dashboard's "Transactions" list only shows
/// orders that actually became a transaction, i.e. `has_invoice`).
class AdminTransaction {
  const AdminTransaction({
    required this.orderId,
    required this.restaurantName,
    required this.restaurantPhone,
    required this.orderNumber,
    required this.invoiceNumber,
    required this.createdAt,
    required this.invoiceTotal,
    required this.isPaid,
  });

  final String orderId;
  final String restaurantName;
  final String restaurantPhone;
  final String orderNumber;
  final String? invoiceNumber;
  final DateTime createdAt;
  final double invoiceTotal;
  final bool isPaid;

  /// No partial-payment tracking exists in the schema (`invoices` only has
  /// a binary pending/paid status, no "amount paid so far" column) — so
  /// this is never a fabricated in-between figure: the full total while
  /// unpaid, zero once paid.
  double get balance => isPaid ? 0 : invoiceTotal;

  factory AdminTransaction.fromJson(Map<String, dynamic> json) {
    return AdminTransaction(
      orderId: json['order_id'] as String,
      restaurantName: json['restaurant_name'] as String,
      restaurantPhone: json['restaurant_phone'] as String,
      orderNumber: json['order_number'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      invoiceTotal: (json['invoice_total'] as num).toDouble(),
      isPaid: json['payment_status'] == 'paid',
    );
  }
}
