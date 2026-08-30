import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/admin_restaurant_option.dart';
import '../domain/sale_line_item.dart';

class AdminOrderRef {
  const AdminOrderRef({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final DateTime createdAt;
}

/// Everything the "Sale" screen needs to reopen an existing transaction for
/// editing — same fields it collects when creating a new one.
class AdminSaleDraft {
  const AdminSaleDraft({
    required this.order,
    required this.restaurant,
    required this.deliveryDate,
    required this.items,
    required this.invoiceTotal,
    required this.isPaid,
    required this.invoiceNumber,
  });

  final AdminOrderRef order;
  final AdminRestaurantOption restaurant;
  final DateTime deliveryDate;
  final List<SaleLineItem> items;

  /// Null if this order was never invoiced (a draft saved but never
  /// finalized).
  final double? invoiceTotal;
  final bool isPaid;
  final String? invoiceNumber;
}

/// Backs the admin "Add Sale" screen — the first admin write path (see
/// migration 20260826000006_admin_add_sale.sql for the RLS behind it).
class AdminSalesRepository {
  AdminSalesRepository(this._client);

  final SupabaseClient _client;

  /// Only approved restaurants — selling to a pending/rejected account
  /// isn't a real operation this app supports.
  Future<List<AdminRestaurantOption>> searchRestaurants(String query) async {
    try {
      var builder = _client
          .from('restaurants')
          .select('id, restaurant_name, phone_number')
          .eq('account_status', 'approved');
      if (query.trim().isNotEmpty) {
        builder = builder.ilike('restaurant_name', '%${query.trim()}%');
      }
      final rows = await builder.order('restaurant_name').limit(20);
      return (rows as List)
          .map(
            (row) =>
                AdminRestaurantOption.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<AdminOrderRef> createOrder({
    required String restaurantId,
    DateTime? deliveryDate,
  }) async {
    try {
      final row = await _client
          .from('orders')
          .insert({
            'restaurant_id': restaurantId,
            if (deliveryDate != null)
              'delivery_date': deliveryDate.toIso8601String().split('T').first,
          })
          .select('id, order_number, created_at')
          .single();
      return AdminOrderRef(
        id: row['id'] as String,
        orderNumber: row['order_number'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<void> updateOrderDeliveryDate({
    required String orderId,
    required DateTime deliveryDate,
  }) async {
    try {
      await _client
          .from('orders')
          .update({
            'delivery_date': deliveryDate.toIso8601String().split('T').first,
          })
          .eq('id', orderId);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Replaces every line item for [orderId] with [items] — simplest
  /// correct way to handle an edited draft without diffing row-by-row.
  Future<void> replaceOrderItems(
    String orderId,
    List<SaleLineItem> items,
  ) async {
    try {
      await _client.from('order_items').delete().eq('order_id', orderId);
      if (items.isEmpty) return;
      await _client.from('order_items').insert([
        for (final item in items)
          {
            'order_id': orderId,
            'item_id': item.itemId,
            'item_name': item.itemName,
            'quantity': item.quantity,
            'unit': item.unit,
            'rate': item.rate,
          },
      ]);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Upsert on `order_id` — re-generating for an already-invoiced order
  /// updates that same invoice (keeping its stable invoice_number) instead
  /// of failing on the unique constraint or creating a duplicate.
  Future<void> generateInvoice({
    required String orderId,
    required double totalAmount,
    required bool isPaid,
  }) async {
    try {
      await _client.from('invoices').upsert({
        'order_id': orderId,
        'total_amount': totalAmount,
        'payment_status': isPaid ? 'paid' : 'pending',
      }, onConflict: 'order_id');
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _client.from('orders').delete().eq('id', orderId);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Loads an existing order + its items + restaurant + invoice (if any)
  /// so the "Sale" screen can reopen it for editing, same shape as a
  /// freshly-created one.
  Future<AdminSaleDraft> fetchOrderForEdit(String orderId) async {
    try {
      // These three don't depend on each other — running them in parallel
      // instead of one after another cuts load time roughly to the slowest
      // single query instead of the sum of all three.
      final results = await Future.wait<Object?>([
        _client
            .from('orders')
            .select(
              'id, order_number, created_at, delivery_date, restaurants(id, restaurant_name, phone_number)',
            )
            .eq('id', orderId)
            .single(),
        _client
            .from('order_items')
            .select('item_id, item_name, quantity, unit, rate')
            .eq('order_id', orderId),
        _client
            .from('invoices')
            .select('total_amount, payment_status, invoice_number')
            .eq('order_id', orderId)
            .maybeSingle(),
      ]);
      final orderRow = results[0] as Map<String, dynamic>;
      final itemRows = results[1] as List;
      final invoiceRow = results[2] as Map<String, dynamic>?;

      final restaurantJson = orderRow['restaurants'] as Map<String, dynamic>;
      final deliveryDateRaw = orderRow['delivery_date'] as String?;

      return AdminSaleDraft(
        order: AdminOrderRef(
          id: orderRow['id'] as String,
          orderNumber: orderRow['order_number'] as String,
          createdAt: DateTime.parse(orderRow['created_at'] as String),
        ),
        restaurant: AdminRestaurantOption.fromJson(restaurantJson),
        deliveryDate: deliveryDateRaw != null
            ? DateTime.parse(deliveryDateRaw)
            : DateTime.now(),
        items: itemRows
            .map(
              (row) => SaleLineItem(
                itemId: row['item_id'] as String,
                itemName: row['item_name'] as String,
                unit: row['unit'] as String,
                quantity: row['quantity'] as int,
                // Orders placed by the restaurant itself never set a rate
                // (only the admin form does) — 0 here just means "no
                // admin-entered rate yet", not a fabricated real price.
                rate: (row['rate'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList(),
        invoiceTotal: invoiceRow == null
            ? null
            : (invoiceRow['total_amount'] as num).toDouble(),
        isPaid: invoiceRow?['payment_status'] == 'paid',
        invoiceNumber: invoiceRow?['invoice_number'] as String?,
      );
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
