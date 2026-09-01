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
  static const _imagesBucket = 'item-images';

  /// `items.image_url` (surfaced through admin_items_console) stores a
  /// storage path, not a ready-to-use URL — same resolution
  /// ItemsRepository uses for the Items screen.
  String? _resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return supabase.storage.from(_imagesBucket).getPublicUrl(path);
  }

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

    // A restaurant-placed order's line items never carry a rate (only the
    // admin_confirm_order RPC sets one, at confirm time) — before that,
    // fall back to the item's current catalog price (item_admin_pricing)
    // so the admin can actually review what an order will cost before
    // deciding to accept it, not just quantities.
    final itemIds = (itemRows as List)
        .map((r) => (r as Map<String, dynamic>)['item_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final catalogPrices = <String, double>{};
    // emoji/image_url so each line item shows its real catalog photo
    // (falling back to its real category emoji) instead of the generic
    // 🥬 placeholder — order_items itself carries neither column.
    final catalogMeta = <String, Map<String, dynamic>>{};
    if (itemIds.isNotEmpty) {
      final pricingRows = await supabase
          .from('item_admin_pricing')
          .select('item_id, price')
          .inFilter('item_id', itemIds);
      for (final row in pricingRows as List) {
        final map = row as Map<String, dynamic>;
        catalogPrices[map['item_id'] as String] = (map['price'] as num).toDouble();
      }

      final catalogRows = await supabase
          .from('admin_items_console')
          .select('id, emoji, image_url')
          .inFilter('id', itemIds);
      for (final row in catalogRows as List) {
        final map = row as Map<String, dynamic>;
        catalogMeta[map['id'] as String] = map;
      }
    }

    final items = itemRows.map((map) {
      final itemId = map['item_id'] as String?;
      final rate = (map['rate'] as num?)?.toDouble() ?? catalogPrices[itemId] ?? 0;
      final meta = catalogMeta[itemId];
      return OrderItem.fromJson({
        'product_id': itemId ?? '',
        'name': map['item_name'],
        'emoji': meta?['emoji'],
        'image_url': meta?['image_url'],
        'unit': map['unit'],
        'qty': map['quantity'],
        'rate': rate,
      }, resolveImageUrl: _resolveImageUrl);
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
