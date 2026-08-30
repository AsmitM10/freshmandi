/// One row of an in-progress admin "Add Sale" form — not persisted until
/// Save/Generate Invoice writes it to `order_items`. `rate` is the
/// admin-entered per-unit price used only to compute this sale's total;
/// it's never shown to the restaurant (see the admin_add_sale migration).
class SaleLineItem {
  const SaleLineItem({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.rate,
  });

  final String itemId;
  final String itemName;
  final String unit;
  final int quantity;
  final double rate;

  double get subtotal => quantity * rate;
}
