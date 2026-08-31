import '../../core/supabase/supabase_client.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';

/// Orders map to this app's real `orders`/`order_items`/`invoices` tables.
/// Reads go through `admin_orders_console` (shaped to match
/// Order.fromJson — see
/// supabase/migrations/20260830000001_business_console_integration.sql),
/// which is itself built on `admin_order_overview`
/// (20260826000001_admin_dashboard.sql).
class OrdersRepository {
  Future<List<Order>> fetchAll({OrderStatus? status, String? search}) async {
    var query = supabase.from('admin_orders_console').select();
    if (status == OrderStatus.confirmed) {
      query = query.eq('status', 'confirmed');
    } else if (status == OrderStatus.pending) {
      // Matches OrderStatusX.fromValue's own definition of "pending": any
      // status string other than 'confirmed' (order_status has more real
      // values than this app's 2-state enum covers — see models/order.dart).
      query = query.neq('status', 'confirmed');
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.or('id.ilike.%$search%,customer_name.ilike.%$search%');
    }
    final rows = await query.order('placed_at', ascending: false);
    return (rows as List).map((r) => Order.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Order> fetchById(String id) async {
    final orderRow = await supabase.from('admin_orders_console').select().eq('id', id).single();
    final itemRows = await supabase
        .from('order_items')
        .select('item_id, item_name, quantity, unit, rate')
        .eq('order_id', id);
    final items = (itemRows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return OrderItem.fromJson({
        'product_id': map['item_id'] ?? '',
        'name': map['item_name'],
        'unit': map['unit'],
        'qty': map['quantity'],
        'rate': map['rate'] ?? 0,
      });
    }).toList();
    return Order.fromJson(orderRow, items: items);
  }

  /// The only order-status action left in the approved scope: Pending →
  /// Confirmed. Also generates the order's invoice, computing the total
  /// from the admin's catalog pricing — see admin_confirm_order() in
  /// supabase/migrations/20260830000001_business_console_integration.sql
  /// for why this can't just be a plain status UPDATE: orders/order_items
  /// never carry a price, so confirming is the only point at which a
  /// total can be produced.
  Future<void> confirm(String id) async {
    await supabase.rpc('admin_confirm_order', params: {'p_order_id': id});
  }

  Future<List<Order>> fetchByCustomer(String customerId) async {
    final rows = await supabase
        .from('admin_orders_console')
        .select()
        .eq('customer_id', customerId)
        .order('placed_at', ascending: false);
    return (rows as List).map((r) => Order.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Order>> fetchToday() async {
    final start = DateTime.now();
    final startOfDay = DateTime(start.year, start.month, start.day).toIso8601String();
    final rows = await supabase.from('admin_orders_console').select().gte('placed_at', startOfDay);
    return (rows as List).map((r) => Order.fromJson(r as Map<String, dynamic>)).toList();
  }
}
