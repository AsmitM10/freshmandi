import 'item_category.dart';

/// Mirrors a row of the `items` table. Deliberately has NO price field —
/// see the ItemCard "FORBIDDEN properties" list in the Figma spec and the
/// items-catalog migration's comment. `unit` is a plain string rather than
/// a Dart enum on purpose: units are data-driven from Supabase, not a
/// hardcoded client-side list.
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.isAvailable,
    required this.sortOrder,
    this.imageUrl,
  });

  /// [resolveImageUrl] turns the raw `image_url` storage path into a
  /// displayable URL (see ItemsRepository) — optional so this factory
  /// still works untouched anywhere a raw already-usable URL is fine.
  factory CatalogItem.fromMap(
    Map<String, dynamic> map, {
    String? Function(String? path)? resolveImageUrl,
  }) {
    final rawImageUrl = map['image_url'] as String?;
    return CatalogItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: (map['category'] as String).toItemCategory(),
      // A handful of live rows have no unit entered yet — falling back to
      // '' rather than throwing keeps one bad row from taking down the
      // entire catalog fetch (a null unit here previously crashed
      // fetchCatalog() for all 98 items, not just the ones missing one).
      unit: map['unit'] as String? ?? '',
      imageUrl: resolveImageUrl != null ? resolveImageUrl(rawImageUrl) : rawImageUrl,
      isAvailable: map['is_active'] as bool,
      sortOrder: map['sort_order'] as int,
    );
  }

  final String id;
  final String name;
  final ItemCategory category;
  final String unit;
  final String? imageUrl;
  final bool isAvailable;
  final int sortOrder;
}
