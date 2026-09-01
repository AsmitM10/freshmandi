import '../../core/supabase/supabase_client.dart';
import '../../models/admin_customer_option.dart';
import '../../models/sale_line_item.dart';

/// A catalog item as shown in the Add Sale item picker — name/unit from
/// `items`, default rate from `item_admin_pricing` (pre-fills the rate
/// field; the admin can still override it per line, same as the original
/// per-sale pricing model this schema was built around).
class SaleCatalogItem {
  const SaleCatalogItem({required this.id, required this.name, required this.unit, required this.defaultRate});

  final String id;
  final String name;
  final String unit;
  final double defaultRate;
}

/// Everything the Add Sale screen needs to reopen an existing draft/sale —
/// same shape whether it's still a plain order or already invoiced.
class SaleDraft {
  const SaleDraft({
    required this.orderId,
    required this.orderNumber,
    required this.customer,
    required this.createdAt,
    required this.items,
    required this.invoiceTotal,
    required this.invoiceNumber,
    required this.receivedAmount,
  });

  final String orderId;
  final String orderNumber;
  final AdminCustomerOption customer;
  final DateTime createdAt;
  final List<SaleLineItem> items;
  final double? invoiceTotal;
  final String? invoiceNumber;
  final double receivedAmount;
}

/// Backs the admin "Add Sale" flow — the admin creates an order directly
/// on a restaurant's behalf (as opposed to the restaurant placing it
/// themselves), prices each line manually, and generates/shares the
/// resulting invoice. Reuses the exact same tables/RLS the restaurant
/// checkout flow does (orders/order_items/invoices — see
/// 20260826000006_admin_add_sale.sql for the admin insert/update/delete
/// policies this depends on) plus the Money In ledger for whatever the
/// admin marks as already received at time of sale.
class AddSaleRepository {
  Future<List<AdminCustomerOption>> searchCustomers(String query) async {
    var builder = supabase.from('restaurants').select('id, restaurant_name, phone_number').eq('account_status', 'approved');
    if (query.trim().isNotEmpty) {
      builder = builder.ilike('restaurant_name', '%${query.trim()}%');
    }
    final rows = await builder.order('restaurant_name').limit(20);
    return (rows as List).map((r) => AdminCustomerOption.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<SaleCatalogItem>> fetchCatalogItems({String? search}) async {
    var builder = supabase.from('admin_items_console').select('id, name, unit, price');
    if (search != null && search.trim().isNotEmpty) {
      builder = builder.ilike('name', '%${search.trim()}%');
    }
    final rows = await builder.order('name');
    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return SaleCatalogItem(
        id: map['id'] as String,
        name: map['name'] as String,
        unit: (map['unit'] as String?) ?? 'kg',
        defaultRate: (map['price'] as num).toDouble(),
      );
    }).toList();
  }

  /// Creates the bare order row a draft sale is built on top of —
  /// order_number is assigned server-side (order_number_seq).
  Future<String> createDraft(String restaurantId) async {
    final row = await supabase.from('orders').insert({'restaurant_id': restaurantId}).select('id').single();
    return row['id'] as String;
  }

  /// Replaces every line item for [orderId] with [items] — simplest
  /// correct way to handle an edited draft without diffing row-by-row.
  Future<void> replaceItems(String orderId, List<SaleLineItem> items) async {
    await supabase.from('order_items').delete().eq('order_id', orderId);
    if (items.isEmpty) return;
    await supabase.from('order_items').insert([
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
  }

  /// Generates (or re-generates) the invoice for [orderId] and, if the
  /// admin recorded a received amount, logs it to the Money In ledger the
  /// same way Record Payment does. Upsert on order_id so re-generating an
  /// already-invoiced sale updates that same invoice (stable
  /// invoice_number) instead of creating a duplicate.
  Future<void> generateInvoice({
    required String orderId,
    required double totalAmount,
    required double receivedAmount,
    required AdminCustomerOption customer,
    required String method,
  }) async {
    await supabase.from('invoices').upsert({
      'order_id': orderId,
      'total_amount': totalAmount,
      'payment_status': receivedAmount >= totalAmount && totalAmount > 0 ? 'paid' : 'pending',
    }, onConflict: 'order_id');

    await supabase.from('orders').update({'status': 'confirmed'}).eq('id', orderId);

    if (receivedAmount > 0) {
      await supabase.from('money_transactions').insert({
        'category': 'Sale Payment',
        'party_id': customer.id,
        'party_name': customer.name,
        'amount': receivedAmount,
        'method': method,
        'ref_type': 'Order',
        'ref_id': orderId,
      });
    }
  }

  Future<void> deleteSale(String orderId) async {
    await supabase.from('orders').delete().eq('id', orderId);
  }

  Future<SaleDraft> fetchForEdit(String orderId) async {
    final results = await Future.wait<Object?>([
      supabase
          .from('orders')
          .select('id, order_number, created_at, restaurants(id, restaurant_name, phone_number)')
          .eq('id', orderId)
          .single(),
      supabase.from('order_items').select('item_id, item_name, quantity, unit, rate').eq('order_id', orderId),
      supabase.from('invoices').select('total_amount, invoice_number').eq('order_id', orderId).maybeSingle(),
      supabase.from('money_transactions').select('amount').eq('ref_id', orderId).eq('ref_type', 'Order'),
    ]);

    final orderRow = results[0] as Map<String, dynamic>;
    final itemRows = results[1] as List;
    final invoiceRow = results[2] as Map<String, dynamic>?;
    final paymentRows = results[3] as List;

    final restaurantJson = orderRow['restaurants'] as Map<String, dynamic>;

    return SaleDraft(
      orderId: orderRow['id'] as String,
      orderNumber: orderRow['order_number'] as String,
      customer: AdminCustomerOption.fromJson(restaurantJson),
      createdAt: DateTime.parse(orderRow['created_at'] as String).toLocal(),
      items: itemRows.map((row) {
        final map = row as Map<String, dynamic>;
        return SaleLineItem(
          itemId: map['item_id'] as String? ?? '',
          itemName: map['item_name'] as String,
          unit: map['unit'] as String,
          quantity: (map['quantity'] as num).toInt(),
          rate: (map['rate'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
      invoiceTotal: invoiceRow == null ? null : (invoiceRow['total_amount'] as num).toDouble(),
      invoiceNumber: invoiceRow?['invoice_number'] as String?,
      receivedAmount: paymentRows.fold<double>(
        0,
        (sum, row) => sum + ((row as Map<String, dynamic>)['amount'] as num).toDouble(),
      ),
    );
  }
}
