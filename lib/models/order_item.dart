class OrderItem {
  final String productId;
  final String name;
  final String emoji;
  final String unit;
  final int qty;
  final double rate;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.emoji,
    required this.unit,
    required this.qty,
    required this.rate,
  });

  double get amount => qty * rate;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['product_id'] as String,
        name: json['name'] as String,
        emoji: (json['emoji'] as String?) ?? '🥬',
        unit: (json['unit'] as String?) ?? 'kg',
        qty: (json['qty'] as num).toInt(),
        rate: (json['rate'] as num).toDouble(),
      );

  Map<String, dynamic> toInsertJson(String orderId) => {
        'order_id': orderId,
        'product_id': productId,
        'name': name,
        'emoji': emoji,
        'unit': unit,
        'qty': qty,
        'rate': rate,
      };
}
