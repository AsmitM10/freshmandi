import '../../core/supabase/supabase_client.dart';
import '../../models/money_transaction.dart';

/// Money In only — Money Out / Expenses are out of the approved scope
/// (removed, not hidden), so this repository never writes a negative or
/// "out" row. `money_transactions` is a real ledger table (not every entry
/// is tied to an order — e.g. "Owner Capital Introduced" has no invoice to
/// derive from) — see
/// supabase/migrations/20260830000001_business_console_integration.sql.
class TransactionsRepository {
  Future<List<MoneyTransaction>> fetchAll({String? search}) async {
    var query = supabase.from('money_transactions').select();
    if (search != null && search.trim().isNotEmpty) {
      query = query.or('category.ilike.%$search%,party_name.ilike.%$search%');
    }
    final rows = await query.order('date', ascending: false);
    return (rows as List).map((r) => MoneyTransaction.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<MoneyTransaction> record({
    required String category,
    String? partyId,
    String? partyName,
    required double amount,
    required String method,
  }) async {
    final row = await supabase
        .from('money_transactions')
        .insert({
          'category': category,
          'party_id': partyId,
          'party_name': partyName,
          'amount': amount,
          'method': method,
          'ref_type': 'Manual',
        })
        .select()
        .single();

    if (partyId != null) {
      // Reduce the customer's outstanding balance by whatever was just
      // received. Goes through a security-definer RPC (not a plain
      // UPDATE) because this admin session doesn't own the restaurant
      // row — see admin_adjust_outstanding_balance() in
      // supabase/migrations/20260830000001_business_console_integration.sql.
      await supabase.rpc('admin_adjust_outstanding_balance', params: {
        'p_restaurant_id': partyId,
        'p_delta': -amount,
      });
    }

    return MoneyTransaction.fromJson(row);
  }
}
