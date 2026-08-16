import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_state.dart';

/// Global cart/order-list state. Deliberately a plain quantity map, not a
/// list of full item objects — item data (name/image/unit) is looked up
/// from the items providers by id where needed, so the cart never holds a
/// stale copy of item details.
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void increment(String itemId) {
    final next = Map<String, int>.from(state.quantities);
    next[itemId] = (next[itemId] ?? 0) + 1;
    state = CartState(quantities: next);
  }

  void decrement(String itemId) {
    final next = Map<String, int>.from(state.quantities);
    final updated = (next[itemId] ?? 0) - 1;
    if (updated <= 0) {
      next.remove(itemId);
    } else {
      next[itemId] = updated;
    }
    state = CartState(quantities: next);
  }

  void remove(String itemId) {
    final next = Map<String, int>.from(state.quantities)..remove(itemId);
    state = CartState(quantities: next);
  }

  void clear() {
    state = const CartState();
  }

  /// Replaces the entire cart with [quantities] — used by "Repeat Order"
  /// to load a historical order's items as the current draft. Entries
  /// with quantity <= 0 are dropped rather than stored, same invariant
  /// increment/decrement already maintain.
  void setAll(Map<String, int> quantities) {
    final next = <String, int>{};
    for (final entry in quantities.entries) {
      if (entry.value > 0) next[entry.key] = entry.value;
    }
    state = CartState(quantities: next);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Convenience selector so widgets that only care about one item's
/// quantity (e.g. a single ItemCard in a long grid) don't rebuild when an
/// unrelated item's quantity changes.
final cartQuantityProvider = Provider.family<int, String>((ref, itemId) {
  return ref.watch(cartProvider.select((state) => state.quantityOf(itemId)));
});

final cartTotalCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.select((state) => state.totalItemCount));
});
