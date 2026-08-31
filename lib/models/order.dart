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
  final double total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final DateTime placed;
  final String? slot;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.placed,
    this.slot,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.amount);

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem> items = const []}) => Order(
        id: json['id'] as String,
        customerId: json['customer_id'] as String,
        customerName: (json['customer_name'] as String?) ?? '',
        items: items,
        total: (json['total'] as num).toDouble(),
        status: OrderStatusX.fromValue(json['status'] as String? ?? 'pending'),
        paymentStatus: PaymentStatusX.fromValue(json['payment_status'] as String? ?? 'pending'),
        paymentMethod: (json['payment_method'] as String?) ?? '—',
        placed: DateTime.parse(json['placed_at'] as String),
        slot: json['slot'] as String?,
      );
}
