/// In-memory quantity-based order list. Not persisted — cart persistence
/// across sessions is an open product decision (see project audit); until
/// answered, session-only is the safe default (never silently sends stale
/// quantities from a previous visit).
class CartState {
  const CartState({this.quantities = const {}});

  /// itemId -> quantity. An item is "in the cart" iff its quantity > 0;
  /// there is no separate "removed" flag.
  final Map<String, int> quantities;

  int quantityOf(String itemId) => quantities[itemId] ?? 0;

  int get totalItemCount => quantities.values.fold(0, (sum, qty) => sum + qty);

  bool get isEmpty => quantities.isEmpty;
}
