import 'order_item.dart';

/// Order status is intentionally limited to Pending/Confirmed only — per
/// approved scope correction, Cancelled/Delivery/other statuses were
/// removed from the admin. Do not add statuses without an approved design
/// change.
enum OrderStatus { pending, confirmed }

enum PaymentStatus { paid, pending }

extension OrderStatusX on OrderStatus {
  String get value => this == OrderStatus.pending ? 'pending' : 'confirmed';
  String get label => this == OrderStatus.pending ? 'Pending' : 'Confirmed';

  static OrderStatus fromValue(String v) => v == 'confirmed' ? OrderStatus.confirmed : OrderStatus.pending;
}

extension PaymentStatusX on PaymentStatus {
  String get value => this == PaymentStatus.paid ? 'paid' : 'pending';
  String get label => this == PaymentStatus.paid ? 'Paid' : 'Pending';

  static PaymentStatus fromValue(String v) => v == 'paid' ? PaymentStatus.paid : PaymentStatus.pending;
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;

  /// Precomputed row count from `admin_order_overview.item_count` — used by
  /// list screens (Dashboard "Recent orders", Orders list), which never
  /// populate [items] (that's only fetched per-order, in
  /// OrdersRepository.fetchById), so `items.length` is always 0 there.
  /// Falls back to `items.length` itself when a caller does have real
  /// items loaded and no separate count came back from the view.
  final int? itemCount;
  final double total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final DateTime placed;
  final String? slot;

  /// Human-friendly identifiers — [id] is a raw UUID, never fit for
  /// display. [orderNumber] falls back to a short prefix of [id] when the
  /// real value is absent (e.g. before
  /// 20260830000002_admin_orders_console_numbers.sql has been applied) so
  /// callers always have something short to show, never the full UUID.
  final String orderNumber;
  final String? invoiceNumber;
  final String? customerPhone;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    this.itemCount,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.placed,
    this.slot,
    required this.orderNumber,
    this.invoiceNumber,
    this.customerPhone,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.amount);

  /// What a list row should show — the view's precomputed count when
  /// present, otherwise however many [items] were actually loaded.
  int get displayItemCount => itemCount ?? items.length;

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem> items = const []}) => Order(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        customerName: (json['customer_name'] as String?) ?? '',
        items: items,
        itemCount: json['item_count'] as int?,
        total: (json['total'] as num).toDouble(),
        status: OrderStatusX.fromValue(json['status'] as String? ?? 'pending'),
        paymentStatus: PaymentStatusX.fromValue(json['payment_status'] as String? ?? 'pending'),
        paymentMethod: (json['payment_method'] as String?) ?? '—',
        // Supabase timestamps come back with a UTC offset; DateTime.parse
        // preserves that offset rather than converting it, so formatting
        // this anywhere without .toLocal() first prints the UTC clock time
        // labeled as if it were the device's own local time (e.g. an order
        // placed at 11:10 PM IST showed as "5:40 PM").
        placed: DateTime.parse(json['placed_at'] as String).toLocal(),
        slot: json['slot'] as String?,
        orderNumber: (json['order_number'] as String?) ?? _shortId(json['id'] as String),
        invoiceNumber: json['invoice_number'] as String?,
        customerPhone: json['customer_phone'] as String?,
      );

  static String _shortId(String id) => '#${id.substring(0, id.length < 8 ? id.length : 8).toUpperCase()}';
}
