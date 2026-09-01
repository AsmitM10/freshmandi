/// A single line on an admin-created sale — mutable draft state used only
/// while building/editing a sale in the UI, distinct from the read-only
/// `OrderItem` used elsewhere once an order is fetched from the server.
class SaleLineItem {
  SaleLineItem({
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

  double get amount => quantity * rate;
}
