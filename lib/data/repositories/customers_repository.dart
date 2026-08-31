import '../../core/supabase/supabase_client.dart';
import '../../models/customer.dart';

/// "Customers" in the Business Console maps to this app's `restaurants` —
/// every restaurant account is a customer of the wholesaler. Reads go
/// through `admin_customers_overview` (shaped to match Customer.fromJson
/// exactly — see the view in
/// supabase/migrations/20260830000001_business_console_integration.sql).
/// Block/Unblock reuses the restaurant's real `account_status`
/// (suspended <-> approved) via a security-definer RPC, since a plain
/// UPDATE can't change it (see that migration's comment on
/// admin_set_customer_blocked).
class CustomersRepository {
  Future<List<Customer>> fetchAll() async {
    final rows = await supabase.from('admin_customers_overview').select().order('business_name');
    return (rows as List).map((r) => Customer.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Customer> fetchById(String id) async {
    final row = await supabase.from('admin_customers_overview').select().eq('id', id).single();
    return Customer.fromJson(row);
  }

  Future<void> setBlocked(String id, bool blocked) async {
    await supabase.rpc('admin_set_customer_blocked', params: {
      'p_restaurant_id': id,
      'p_blocked': blocked,
    });
  }
}
