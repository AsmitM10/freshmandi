import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../items/domain/catalog_item.dart';
import '../../../items/presentation/providers/items_providers.dart';
import '../../data/orders_repository.dart';
import '../../domain/history_tab.dart';
import '../../domain/order_history_entry.dart';
import '../../domain/order_line_item.dart';
import 'cart_providers.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(supabaseClientProvider));
});

/// Builds order lines from the current cart + already-cached catalog and
/// submits a real order, clearing the cart on success. Shared by the Cart
/// screen's Place Order button and the failure screen's Try Again retry so
/// both go through the exact same submission path rather than duplicating
/// it — throws an [AppException] on any failure (network, empty cart,
/// catalog not loaded, etc.) for the caller to catch and display.
Future<String> submitCartOrder(WidgetRef ref) async {
  final restaurant = ref.read(currentRestaurantProvider).valueOrNull;
  if (restaurant == null) {
    throw const AppException('Could not verify your account. Please try again.');
  }
  final catalog = ref.read(catalogProvider).valueOrNull;
  if (catalog == null) {
    throw const AppException('Catalog not loaded yet. Please try again.');
  }
  final cartState = ref.read(cartProvider);
  if (cartState.isEmpty) {
    throw const AppException('Your cart is empty.');
  }

  final lines = <OrderLineItem>[];
  for (final entry in cartState.quantities.entries) {
    CatalogItem? item;
    for (final candidate in catalog) {
      if (candidate.id == entry.key) {
        item = candidate;
        break;
      }
    }
    if (item == null) continue;
    lines.add(
      OrderLineItem(itemId: item.id, itemName: item.name, quantity: entry.value, unit: item.unit),
    );
  }
  if (lines.isEmpty) {
    throw const AppException('None of the items in your cart are available anymore.');
  }

  final orderId = await ref
      .read(ordersRepositoryProvider)
      .placeOrder(restaurantId: restaurant.id, lines: lines);
  ref.read(cartProvider.notifier).clear();
  return orderId;
}

/// The item lines for one order (order detail screen). Keyed by order id
/// so navigating between different orders' detail screens doesn't share
/// stale state.
final orderItemsProvider = FutureProvider.family<List<OrderLineItem>, String>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).fetchOrderItems(orderId);
});

/// The summary row (date, status, order no., delivery date, invoice total)
/// for one order — the Invoice screen needs this in addition to the item
/// lines above, since it re-shows the same summary card as the History
/// list.
final orderSummaryProvider = FutureProvider.family<OrderHistoryEntry, String>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).fetchOrderSummary(orderId);
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
