import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/settings_repository.dart';
import 'categories_providers.dart';
import 'customers_providers.dart';
import 'dashboard_providers.dart';
import 'items_providers.dart';
import 'orders_providers.dart';
import 'repository_providers.dart';
import 'transactions_providers.dart';

final taxSettingsProvider = FutureProvider.autoDispose<TaxSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).fetchTaxSettings();
});

enum SyncStatus { idle, syncing, synced, failed }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSynced;
  final String? errorMessage;

  const SyncState({required this.status, this.lastSynced, this.errorMessage});

  SyncState copyWith({SyncStatus? status, DateTime? lastSynced, String? errorMessage}) => SyncState(
        status: status ?? this.status,
        lastSynced: lastSynced ?? this.lastSynced,
        errorMessage: errorMessage,
      );
}

/// Business Account & Sync — "Sync Data" now has a real backend to talk to
/// (unlike the original HTML prototype, which deliberately never faked a
/// sync because nothing was connected). Here it re-pulls every screen's
/// data from Supabase and reports genuine success/failure — it does not
/// fabricate a result either way.
///
/// PRODUCT DECISION REQUIRED: if "Sync Data" is meant to mean something
/// more specific (e.g. reconciling an offline queue, or syncing against the
/// customer-facing app's own data), confirm that and this can be pointed at
/// the right operation instead of a plain refresh.
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(const SyncState(status: SyncStatus.idle));

  final Ref _ref;

  Future<void> sync() async {
    state = state.copyWith(status: SyncStatus.syncing);
    try {
      _ref.invalidate(dashboardSnapshotProvider);
      _ref.invalidate(allItemsProvider);
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(ordersListProvider);
      _ref.invalidate(allCustomersProvider);
      _ref.invalidate(transactionsListProvider);

      // Touch one query so a real failure (bad credentials, RLS, network)
      // surfaces here instead of silently deferring to whichever widget
      // happens to rebuild first.
      await _ref.read(dashboardSnapshotProvider.future);

      state = SyncState(status: SyncStatus.synced, lastSynced: DateTime.now());
    } catch (e) {
      state = state.copyWith(status: SyncStatus.failed, errorMessage: e.toString());
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) => SyncNotifier(ref));
