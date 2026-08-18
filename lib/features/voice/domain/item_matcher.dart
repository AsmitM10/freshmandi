import '../../items/domain/catalog_item.dart';
import 'parsed_voice_item.dart';

/// Result of matching one spoken item-name phrase against the real catalog.
class ItemMatchResult {
  const ItemMatchResult.matched(CatalogItem matchedItem)
    : status = VoiceMatchStatus.matched,
      item = matchedItem,
      candidates = const [];

  const ItemMatchResult.ambiguous(this.candidates)
    : status = VoiceMatchStatus.ambiguous,
      item = null;

  const ItemMatchResult.unmatched()
    : status = VoiceMatchStatus.unmatched,
      item = null,
      candidates = const [];

  final VoiceMatchStatus status;
  final CatalogItem? item;
  final List<CatalogItem> candidates;
}

/// Matches a spoken item-name phrase against the real Supabase catalog —
/// never the other way around, and never a fabricated item. There is no
/// `aliases` column on `items` in the live schema (only id/name/category/
/// unit/image_url/is_active/sort_order — see CatalogItem), so alias
/// matching isn't implemented; the layered normalized/fuzzy matching below
/// is what stands in for it. All matching runs against the already-cached
/// catalog list passed in — this class never queries Supabase itself.
class ItemMatcher {
  const ItemMatcher();

  static const _maxAmbiguousCandidates = 4;

  ItemMatchResult match(String rawName, List<CatalogItem> catalog) {
    final available = catalog.where((item) => item.isAvailable).toList();
    final normalized = _normalize(rawName);
    if (normalized.isEmpty || available.isEmpty) {
      return const ItemMatchResult.unmatched();
    }

    // 1. Exact match on the normalized name.
    for (final item in available) {
      if (_normalize(item.name) == normalized) {
        return ItemMatchResult.matched(item);
      }
    }

    // 2. Singular/plural tolerant match — "tomatoes" said, "Tomato" stored
    // (or vice versa).
    final singular = _singularize(normalized);
    for (final item in available) {
      final itemNormalized = _normalize(item.name);
      if (itemNormalized == singular || _singularize(itemNormalized) == singular) {
        return ItemMatchResult.matched(item);
      }
    }

    // 3. Substring match — catches "tomato" resolving to a catalog entry
    // like "Desi Tomato" or "Tomato Hybrid". Exactly one hit is a
    // confident match; more than one is genuinely ambiguous and must be
    // handed to the user rather than guessed.
    final substringMatches = available.where((item) {
      final itemNormalized = _singularize(_normalize(item.name));
      return itemNormalized.contains(singular) || singular.contains(itemNormalized);
    }).toList();
    if (substringMatches.length == 1) {
      return ItemMatchResult.matched(substringMatches.single);
    }
    if (substringMatches.length > 1) {
      return ItemMatchResult.ambiguous(substringMatches.take(_maxAmbiguousCandidates).toList());
    }

    // 4. Controlled fuzzy match — tolerates a single mis-heard letter
    // ("brinjal" vs "brinjol") without matching unrelated words. The
    // allowed edit distance scales with word length and is capped small
    // on purpose: this is a safety margin for speech-recognition noise,
    // not a general fuzzy search.
    CatalogItem? bestItem;
    var bestDistance = 1 << 30;
    var secondBestDistance = 1 << 30;
    for (final item in available) {
      final distance = _levenshtein(singular, _singularize(_normalize(item.name)));
      if (distance < bestDistance) {
        secondBestDistance = bestDistance;
        bestDistance = distance;
        bestItem = item;
      } else if (distance < secondBestDistance) {
        secondBestDistance = distance;
      }
    }
    final maxAllowed = (singular.length / 4).ceil().clamp(1, 2);
    // Require the best match to be unambiguously better than the runner-up
    // too, not just within tolerance — otherwise two similarly-close
    // catalog names would silently pick whichever happened to be first.
    if (bestItem != null && bestDistance <= maxAllowed && bestDistance < secondBestDistance) {
      return ItemMatchResult.matched(bestItem);
    }

    return const ItemMatchResult.unmatched();
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _singularize(String normalized) {
    if (normalized.length > 3 && normalized.endsWith('ies')) {
      return '${normalized.substring(0, normalized.length - 3)}y';
    }
    if (normalized.length > 3 && normalized.endsWith('es')) {
      return normalized.substring(0, normalized.length - 2);
    }
    if (normalized.length > 3 && normalized.endsWith('s')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previousRow = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final currentRow = List<int>.filled(b.length + 1, 0);
      currentRow[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1,
          previousRow[j + 1] + 1,
          previousRow[j] + cost,
        ].reduce((v, e) => v < e ? v : e);
      }
      previousRow = currentRow;
    }
    return previousRow[b.length];
  }
}
