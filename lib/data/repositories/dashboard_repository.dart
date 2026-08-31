import '../../core/supabase/supabase_client.dart';
import '../../models/order.dart';

class DashboardSnapshot {
  final double salesToday;
  final double moneyInToday;
  final int pendingOrders;
  final int confirmedOrders;
  final double totalReceivable;

  const DashboardSnapshot({
    required this.salesToday,
    required this.moneyInToday,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.totalReceivable,
  });
}

/// Aggregates for the Home dashboard. Implemented as a few plain queries
/// composed client-side rather than a Postgres view/RPC — fine at admin
/// scale; move to a `dashboard_snapshot()` SQL function if this ever needs
/// to run against a large orders table.
///
/// `admin_orders_console` and `admin_revenue_summary` are views over the
/// real orders/invoices tables (see
/// supabase/migrations/20260830000001_business_console_integration.sql and
/// 20260826000001_admin_dashboard.sql) — `totalReceivable` in particular
/// comes from `admin_revenue_summary`, a real sum over unpaid invoices,
/// rather than the restaurants.outstanding_balance ledger column (which
/// only reflects manual Transactions entries — see
/// TransactionsRepository).
class DashboardRepository {
  Future<DashboardSnapshot> fetch() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final todayOrdersRows = await supabase.from('admin_orders_console').select().gte('placed_at', startOfDay);
    final todayOrders = (todayOrdersRows as List)
        .map((r) => Order.fromJson(r as Map<String, dynamic>))
        .toList();

    final salesToday = todayOrders.fold<double>(0, (sum, o) => sum + o.total);
    final pendingOrders = todayOrders.where((o) => o.status == OrderStatus.pending).length;
    final confirmedOrders = todayOrders.where((o) => o.status == OrderStatus.confirmed).length;

    final todayTxnRows = await supabase.from('money_transactions').select('amount').gte('date', startOfDay);
    final moneyInToday = (todayTxnRows as List)
        .fold<double>(0, (sum, r) => sum + ((r as Map<String, dynamic>)['amount'] as num).toDouble());

    final receivableRow = await supabase.from('admin_revenue_summary').select('total_receivable').single();
    final totalReceivable = (receivableRow['total_receivable'] as num).toDouble();

    return DashboardSnapshot(
      salesToday: salesToday,
      moneyInToday: moneyInToday,
      pendingOrders: pendingOrders,
      confirmedOrders: confirmedOrders,
      totalReceivable: totalReceivable,
    );
  }
}
