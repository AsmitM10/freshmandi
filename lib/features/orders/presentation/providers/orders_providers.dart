import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/orders_repository.dart';
import '../../domain/history_tab.dart';
import '../../domain/order_history_entry.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseClientProvider));
});

/// Which History tab is selected. Each tab keeps its own cached page list
/// (see [historyControllerProvider]) so switching back and forth doesn't
/// refetch — only `retry()`/`loadMore()` hit Supabase again.
final selectedHistoryTabProvider = StateProvider<HistoryTab>(
  (ref) => HistoryTab.allOrders,
);

class HistoryState {
  const HistoryState({
    this.entries = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<OrderHistoryEntry> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  HistoryState copyWith({
    List<OrderHistoryEntry>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// One paginated history list per tab. `.family` gives each
/// [HistoryTab] its own independent state/cache — switching tabs is a
/// free UI-only change (no Supabase call) unless that tab has never been
/// loaded yet or the user explicitly retries/scrolls for more.
class HistoryController extends FamilyNotifier<HistoryState, HistoryTab> {
  late HistoryTab _tab;
  int _page = 0;

  @override
  HistoryState build(HistoryTab arg) {
    _tab = arg;
    _page = 0;
    Future.microtask(_loadFirstPage);
    return const HistoryState(isLoading: true);
  }

  Future<void> _loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref.read(ordersRepositoryProvider).fetchHistoryPage(tab: _tab, page: 0);
      _page = 0;
      state = HistoryState(
        entries: page,
        hasMore: page.length == OrdersRepository.pageSize,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> retry() => _loadFirstPage();

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = _page + 1;
      final page = await ref
          .read(ordersRepositoryProvider)
          .fetchHistoryPage(tab: _tab, page: nextPage);
      _page = nextPage;
      state = state.copyWith(
        entries: [...state.entries, ...page],
        isLoadingMore: false,
        hasMore: page.length == OrdersRepository.pageSize,
      );
    } catch (error) {
      // A failed "load more" keeps the existing list visible rather than
      // replacing it with an error state — only the initial load does
      // that. The user can just scroll again to retry.
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final historyControllerProvider =
    NotifierProvider.family<HistoryController, HistoryState, HistoryTab>(
      HistoryController.new,
    );
