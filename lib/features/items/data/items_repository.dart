import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/catalog_item.dart';

/// Reads the restaurant-facing catalog. RLS (see items-catalog migration)
/// only grants SELECT to `authenticated` — no write path exists here at
/// all, catalog management is admin-only and out of this app's scope.
class ItemsRepository {
  ItemsRepository(this._client);

  final SupabaseClient _client;

  static const _imagesBucket = 'item-images';

  /// The full catalog (~193 items), fetched once. Category filtering and
  /// search both run client-side over this same list (see
  /// items_providers.dart) rather than issuing a new Supabase request per
  /// category tap or keystroke — the catalog is small enough that this is
  /// both simpler and cheaper than round-tripping to Supabase repeatedly.
  Future<List<CatalogItem>> fetchCatalog() async {
    try {
      final rows = await _client.from('items').select().order('sort_order');
      return rows.map((row) => CatalogItem.fromMap(row, resolveImageUrl: _resolveImageUrl)).toList();
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// `items.image_url` stores a storage path (e.g. 'fruits/apple.png'), not
  /// a ready-to-use URL. Null/empty paths pass through unchanged — the
  /// ItemCard's own fallback handles those, same as an invalid path once
  /// CachedNetworkImage fails to load the resolved URL.
  String? _resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return _client.storage.from(_imagesBucket).getPublicUrl(path);
  }
}
