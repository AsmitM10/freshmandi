import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/catalog_item.dart';
import '../../domain/item_category.dart';
import '../../data/items_repository.dart';

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepository(ref.watch(supabaseClientProvider));
});

/// The full catalog (~193 items), fetched once and kept alive — category
/// filtering and search both derive from this instead of each issuing
/// their own Supabase request. Use `ref.refresh(catalogProvider)` for the
/// retry action on the error state.
final catalogProvider = FutureProvider<List<CatalogItem>>((ref) {
  return ref.watch(itemsRepositoryProvider).fetchCatalog();
});

/// The current text in the search field. Empty string = no search active.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Which category chip is selected on the Shop screen. Also set by Home's
/// "Browse Category" cards before navigating to Shop, so tapping e.g. the
/// Fruits card lands directly on the Fruits grid. Search operates within
/// whichever category is selected, not across the whole catalog.
final selectedCategoryProvider = StateProvider<ItemCategory>(
  (ref) => ItemCategory.indianVegetables,
);

/// The catalog filtered by the selected category and, if present, the
/// search query (case-insensitive name match) — both applied together,
/// entirely client-side, over the one cached catalog fetch.
final filteredItemsProvider = Provider<AsyncValue<List<CatalogItem>>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return ref.watch(catalogProvider).whenData((items) {
    return items.where((item) {
      if (item.category != category) return false;
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query);
    }).toList();
  });
});
