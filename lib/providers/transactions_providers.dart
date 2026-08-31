import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/money_transaction.dart';
import 'repository_providers.dart';

final transactionsSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final transactionsListProvider = FutureProvider.autoDispose<List<MoneyTransaction>>((ref) {
  final search = ref.watch(transactionsSearchProvider);
  return ref.watch(transactionsRepositoryProvider).fetchAll(search: search);
});

/// Unfiltered, used for the Received-today / Received-this-month stat cards
/// so a search doesn't skew the totals shown above the list.
final allTransactionsProvider = FutureProvider.autoDispose<List<MoneyTransaction>>((ref) {
  return ref.watch(transactionsRepositoryProvider).fetchAll();
});
