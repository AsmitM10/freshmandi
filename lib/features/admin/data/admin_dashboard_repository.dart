import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/admin_revenue_summary.dart';
import '../domain/admin_transaction.dart';

class AdminDashboardRepository {
  AdminDashboardRepository(this._client);

  final SupabaseClient _client;

  Future<AdminRevenueSummary> fetchRevenueSummary() async {
    try {
      final row = await _client.from('admin_revenue_summary').select().single();
      return AdminRevenueSummary.fromJson(row);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<List<AdminTransaction>> fetchRecentTransactions({
    int limit = 6,
  }) async {
    try {
      final rows = await _client
          .from('admin_order_overview')
          .select()
          .eq('has_invoice', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((row) => AdminTransaction.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Every invoiced transaction whose `created_at` falls on [date] (its
  /// local calendar day) — backs the Day Book screen.
  Future<List<AdminTransaction>> fetchTransactionsForDate(DateTime date) {
    return fetchTransactionsForRange(date, date);
  }

  /// Every invoiced transaction whose `created_at` falls between [from] and
  /// [to], both inclusive calendar days — backs the All Transactions
  /// screen (and Day Book, as the single-day case of the same range).
  Future<List<AdminTransaction>> fetchTransactionsForRange(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final rangeStart = DateTime(from.year, from.month, from.day);
      final rangeEnd = DateTime(
        to.year,
        to.month,
        to.day,
      ).add(const Duration(days: 1));
      final rows = await _client
          .from('admin_order_overview')
          .select()
          .eq('has_invoice', true)
          .gte('created_at', rangeStart.toIso8601String())
          .lt('created_at', rangeEnd.toIso8601String())
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => AdminTransaction.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
