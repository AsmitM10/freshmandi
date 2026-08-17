import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/history_tab.dart';
import '../domain/order_history_entry.dart';
import '../domain/order_line_item.dart';

/// Reads order/invoice history and order line items. RLS (see the
/// orders-history migration) resolves ownership through the caller's own
/// session, not any client-supplied id — a restaurant can never read
/// another restaurant's orders no matter what this repository is asked
/// for.
class OrdersRepository {
  OrdersRepository(this._client);

  final SupabaseClient _client;

  static const pageSize = 20;

  /// Newest-first, paginated via `.range()` so a restaurant with a long
  /// history never loads its whole order list into memory at once.
  Future<List<OrderHistoryEntry>> fetchHistoryPage({
    required HistoryTab tab,
    required int page,
  }) async {
    try {
      var query = _client.from('order_history').select();
      switch (tab) {
        case HistoryTab.allOrders:
          break;
        case HistoryTab.transaction:
          query = query.eq('has_invoice', true);
        case HistoryTab.pendingInvoice:
          query = query.eq('has_invoice', false);
      }
      final from = page * pageSize;
      final rows = await query
          .order('created_at', ascending: false)
          .range(from, from + pageSize - 1);
      return rows.map(OrderHistoryEntry.fromMap).toList();
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Single-order summary for the Invoice/Order Detail screen — same
  /// `order_history` view as the list, filtered to one row.
  Future<OrderHistoryEntry> fetchOrderSummary(String orderId) async {
    try {
      final row = await _client.from('order_history').select().eq('order_id', orderId).single();
      return OrderHistoryEntry.fromMap(row);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<List<OrderLineItem>> fetchOrderItems(String orderId) async {
    try {
      final rows = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('created_at');
      return rows.map(OrderLineItem.fromMap).toList();
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Creates a real order from the cart: one `orders` row (status defaults
  /// to 'submitted' — see the migration), then one `order_items` row per
  /// line, each snapshotting the item's current name/unit rather than a
  /// live reference. `restaurantId` must be the caller's own restaurant
  /// (resolved by the caller via `auth.uid()`, same as everywhere else) —
  /// RLS still rejects any other id regardless. No price is ever written
  /// here or anywhere on these two tables.
  Future<String> placeOrder({
    required String restaurantId,
    required List<OrderLineItem> lines,
  }) async {
    try {
      final orderRow = await _client
          .from('orders')
          .insert({'restaurant_id': restaurantId})
          .select('id')
          .single();
      final orderId = orderRow['id'] as String;
      await _client.from('order_items').insert([
        for (final line in lines)
          {
            'order_id': orderId,
            'item_id': line.itemId,
            'item_name': line.itemName,
            'quantity': line.quantity,
            'unit': line.unit,
          },
      ]);
      return orderId;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
