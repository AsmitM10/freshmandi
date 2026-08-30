/// Mirrors `public.admin_revenue_summary` — a single-row aggregate over
/// every invoice this admin session is allowed to see (i.e. all of them).
class AdminRevenueSummary {
  const AdminRevenueSummary({
    required this.totalReceivable,
    required this.totalSale,
  });

  /// Sum of unpaid invoice totals — "You will get".
  final double totalReceivable;

  /// Sum of every invoice total ever generated — "Sale".
  final double totalSale;

  factory AdminRevenueSummary.fromJson(Map<String, dynamic> json) {
    return AdminRevenueSummary(
      totalReceivable: (json['total_receivable'] as num).toDouble(),
      totalSale: (json['total_sale'] as num).toDouble(),
    );
  }
}
