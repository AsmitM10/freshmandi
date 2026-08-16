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
}
