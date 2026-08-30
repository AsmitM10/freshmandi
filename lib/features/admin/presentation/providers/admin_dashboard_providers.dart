import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/admin_dashboard_repository.dart';
import '../../domain/admin_revenue_summary.dart';
import '../../domain/admin_transaction.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((
  ref,
) {
  return AdminDashboardRepository(ref.watch(supabaseClientProvider));
});

final adminRevenueSummaryProvider =
    FutureProvider.autoDispose<AdminRevenueSummary>((ref) {
      return ref.watch(adminDashboardRepositoryProvider).fetchRevenueSummary();
    });

final adminRecentTransactionsProvider =
    FutureProvider.autoDispose<List<AdminTransaction>>((ref) {
      return ref
          .watch(adminDashboardRepositoryProvider)
          .fetchRecentTransactions();
    });

/// Keyed by calendar day (year/month/day only) so re-picking the same date
/// on the Day Book screen reuses the cached result instead of refetching.
final adminDayBookTransactionsProvider = FutureProvider.autoDispose
    .family<List<AdminTransaction>, DateTime>((ref, date) {
      return ref
          .watch(adminDashboardRepositoryProvider)
          .fetchTransactionsForDate(date);
    });

/// Keyed by a (from, to) record — records have structural equality, so
/// re-picking the same range on the All Transactions screen reuses the
/// cached result instead of refetching.
final adminTransactionsForRangeProvider = FutureProvider.autoDispose
    .family<List<AdminTransaction>, (DateTime, DateTime)>((ref, range) {
      return ref
          .watch(adminDashboardRepositoryProvider)
          .fetchTransactionsForRange(range.$1, range.$2);
    });
