/// One line of an order's item list (order detail screen + Repeat Order).
/// Name/unit are snapshotted at order time, not looked up live — see the
/// `order_items` migration comment. No price field, ever.
class OrderLineItem {
  const OrderLineItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  factory OrderLineItem.fromMap(Map<String, dynamic> map) => OrderLineItem(
    itemId: map['item_id'] as String?,
    itemName: map['item_name'] as String,
    quantity: map['quantity'] as int,
    unit: map['unit'] as String,
  );

  /// Null if the catalog item this line referenced has since been
  /// deleted (`order_items.item_id` is `on delete set null`) — the
  /// historical name/quantity/unit still display fine, but Repeat Order
  /// can't re-add a line with no item to add.
  final String? itemId;
  final String itemName;
  final int quantity;
  final String unit;
}
