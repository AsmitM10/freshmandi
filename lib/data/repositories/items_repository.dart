import '../../core/supabase/supabase_client.dart';
import '../../models/product.dart';

/// "Items"/"Products" maps to this app's real `items` catalog, which
/// deliberately carries no price (see 20260808000004_items_catalog.sql) —
/// ordinary restaurant users can SELECT every row via their own `items`
/// policy, so pricing lives in a separate, admin-only `item_admin_pricing`
/// table instead of a column on `items` itself (kept faithful to that
/// migration's own stated intent). Reads go through `admin_items_console`,
/// which joins both plus the admin `categories` table — see
/// supabase/migrations/20260830000001_business_console_integration.sql.
class ItemsRepository {
  static const _imagesBucket = 'item-images';

  /// `items.image_url` (surfaced through admin_items_console) stores a
  /// storage path (e.g. 'fruits/apple.png'), not a ready-to-use URL — same
  /// resolution the restaurant-facing catalog does in
  /// features/items/data/items_repository.dart.
  String? _resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return supabase.storage.from(_imagesBucket).getPublicUrl(path);
  }

  Future<List<Product>> fetchAll() async {
    final rows = await supabase.from('admin_items_console').select().order('name');
    return (rows as List)
        .map((r) => Product.fromJson(r as Map<String, dynamic>, resolveImageUrl: _resolveImageUrl))
        .toList();
  }

  Future<Product> create({
    required String name,
    required String categoryId,
    required String categoryName,
    required String unit,
    required double price,
    required double mrp,
    int? stock,
  }) async {
    final itemRow = await supabase
        .from('items')
        .insert({
          'name': name,
          'category': categoryName,
          'unit': unit,
          'is_active': true,
        })
        .select('id')
        .single();
    final itemId = itemRow['id'] as String;

    await supabase.from('item_admin_pricing').insert({
      'item_id': itemId,
      'price': price,
      'mrp': mrp,
      if (stock != null) 'stock': stock,
    });

    final row = await supabase.from('admin_items_console').select().eq('id', itemId).single();
    return Product.fromJson(row, resolveImageUrl: _resolveImageUrl);
  }

  Future<Product> update(Product product) async {
    await supabase
        .from('items')
        .update({
          'name': product.name,
          'category': product.categoryName,
          'unit': product.unit,
          'is_active': product.active,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', product.id);

    await supabase.from('item_admin_pricing').upsert({
      'item_id': product.id,
      'price': product.price,
      'mrp': product.mrp,
      'stock': product.stock,
    });

    final row = await supabase.from('admin_items_console').select().eq('id', product.id).single();
    return Product.fromJson(row, resolveImageUrl: _resolveImageUrl);
  }

  Future<void> delete(String id) async {
    await supabase.from('items').delete().eq('id', id);
  }
}
