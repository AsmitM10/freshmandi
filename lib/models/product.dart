/// A catalogue item ("Item" in the admin UI).
///
/// NOTE: `stock` is kept as a plain, admin-entered number (never inferred)
/// so the data model doesn't need reshaping if stock management is
/// reintroduced later. Per the approved scope, the Items screen does NOT
/// show or compute any Availability/Low Stock/Out of Stock state from it —
/// FreshMandi does not currently run a fixed-inventory system.
class Product {
  final String id;
  final String sku;
  final String name;
  final String categoryId;
  final String categoryName;
  final String emoji;
  final String? imageUrl;
  final String unit;
  final double price;
  final double mrp;
  final bool active;
  final int? stock;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.emoji,
    this.imageUrl,
    required this.unit,
    required this.price,
    required this.mrp,
    this.active = true,
    this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json, {String? categoryName, String? Function(String? path)? resolveImageUrl}) => Product(
        id: json['id'] as String,
        sku: (json['sku'] as String?) ?? '',
        name: json['name'] as String,
        // Nullable in the admin_items_console view when an item's
        // (free-text) category doesn't match any row in the admin
        // `categories` table — e.g. real catalog data that has drifted
        // from the seeded category names. Falls back to '' rather than
        // crashing; the Add/Edit Item sheet already treats an unmatched
        // categoryId as "no selection" and defaults to the first category.
        categoryId: json['category_id'] as String? ?? '',
        categoryName: categoryName ?? (json['category_name'] as String? ?? ''),
        emoji: (json['emoji'] as String?) ?? '🥬',
        imageUrl: resolveImageUrl != null ? resolveImageUrl(json['image_url'] as String?) : json['image_url'] as String?,
        unit: (json['unit'] as String?) ?? 'kg',
        price: (json['price'] as num).toDouble(),
        mrp: (json['mrp'] as num?)?.toDouble() ?? (json['price'] as num).toDouble(),
        active: (json['status'] as String? ?? 'active') == 'active',
        stock: json['stock'] as int?,
      );

  Map<String, dynamic> toInsertJson() => {
        'sku': sku,
        'name': name,
        'category_id': categoryId,
        'emoji': emoji,
        'unit': unit,
        'price': price,
        'mrp': mrp,
        'status': active ? 'active' : 'inactive',
        if (stock != null) 'stock': stock,
      };

  Product copyWith({
    String? name,
    String? categoryId,
    String? categoryName,
    String? unit,
    double? price,
    double? mrp,
    int? stock,
  }) =>
      Product(
        id: id,
        sku: sku,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        emoji: emoji,
        imageUrl: imageUrl,
        unit: unit ?? this.unit,
        price: price ?? this.price,
        mrp: mrp ?? this.mrp,
        active: active,
        stock: stock ?? this.stock,
      );
}
