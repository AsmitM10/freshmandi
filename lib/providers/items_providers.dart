import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import 'repository_providers.dart';

/// All items, unfiltered — fetched once and filtered client-side (search +
/// category), matching how the approved design filters instantly without a
/// round trip per keystroke. Call `ref.invalidate(allItemsProvider)` after
/// any create/update/delete.
final allItemsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(itemsRepositoryProvider).fetchAll();
});

final itemsSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final itemsCategoryFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');

final filteredItemsProvider = Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final itemsAsync = ref.watch(allItemsProvider);
  final search = ref.watch(itemsSearchProvider).trim().toLowerCase();
  final category = ref.watch(itemsCategoryFilterProvider);

  return itemsAsync.whenData((items) {
    var list = items;
    if (category != 'All') {
      list = list.where((p) => p.categoryName == category).toList();
    }
    if (search.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(search) || p.sku.toLowerCase().contains(search)).toList();
    }
    return list;
  });
});
