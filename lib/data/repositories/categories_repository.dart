import '../../core/supabase/supabase_client.dart';
import '../../models/category.dart';

/// Backs the admin's category picker (Items screen). This is an
/// admin-managed reference list — see `categories` in
/// supabase/migrations/20260830000001_business_console_integration.sql —
/// kept deliberately separate from the restaurant-facing `items.category`
/// free-text column, which is unaffected by anything here.
class CategoriesRepository {
  Future<List<Category>> fetchAll() async {
    final rows = await supabase.from('categories').select().order('name');
    return (rows as List).map((r) => Category.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// The 3 categories approved as *filter* options on the Items screen.
  /// Kept as a fixed, hard-coded list (not derived from the `categories`
  /// table) per the explicit client correction: the filter dropdown must
  /// show exactly these three, regardless of what other categories exist.
  /// Matched exactly against `items.category`'s real values (confirmed
  /// against the live table — 268 rows, all one of these three strings),
  /// not a guessed/short form — filteredItemsProvider compares by exact
  /// equality, so anything else here silently matches nothing.
  static const List<String> approvedFilterCategories = [
    'Fruits',
    'Indian Vegetables',
    'Exotic Vegetables',
  ];

  Future<Category> create({required String name, required String emoji}) async {
    final row = await supabase
        .from('categories')
        .insert({'name': name, 'emoji': emoji, 'status': 'active'})
        .select()
        .single();
    return Category.fromJson(row);
  }
}
