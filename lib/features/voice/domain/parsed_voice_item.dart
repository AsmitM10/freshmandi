import '../../items/domain/catalog_item.dart';

/// Outcome of matching one spoken item phrase ("tamatar", "green...")
/// against the real Supabase catalog. Never invents an item: [matched] is
/// the only status that carries a concrete [CatalogItem] the order can
/// actually use.
enum VoiceMatchStatus {
  /// Resolved to exactly one real catalog item.
  matched,

  /// More than one real catalog item is a plausible match — the user must
  /// pick which one, never guessed automatically.
  ambiguous,

  /// No real catalog item was found close enough to trust.
  unmatched,
}

/// One item phrase recognized out of the spoken transcript, plus whatever
/// the [ItemMatcher] could resolve it to. No price field anywhere on this
/// class or anything derived from it — the no-item-price rule applies to
/// voice-ordered items exactly the same as manually-added ones.
class ParsedVoiceItem {
  const ParsedVoiceItem({
    required this.rawText,
    required this.quantity,
    required this.status,
    this.matchedItem,
    this.candidates = const [],
  });

  /// The item-name phrase as heard, before matching (e.g. "tomato",
  /// "green capsicum") — shown back to the user for ambiguous/unmatched
  /// items so they can tell what the recognizer actually heard.
  final String rawText;

  final int quantity;

  final VoiceMatchStatus status;

  /// Set only when [status] is [VoiceMatchStatus.matched].
  final CatalogItem? matchedItem;

  /// Set only when [status] is [VoiceMatchStatus.ambiguous] — the real
  /// candidates the user chooses between, never more than a handful.
  final List<CatalogItem> candidates;

  /// The unit actually used for this line, always the catalog item's own
  /// configured unit (per the "Supabase unit is the final source of
  /// truth" rule) — never what the user happened to say, and never
  /// invented when there's no matched item yet.
  String get unit => matchedItem?.unit ?? '';

  ParsedVoiceItem copyWith({
    VoiceMatchStatus? status,
    CatalogItem? matchedItem,
    List<CatalogItem>? candidates,
  }) {
    return ParsedVoiceItem(
      rawText: rawText,
      quantity: quantity,
      status: status ?? this.status,
      matchedItem: matchedItem ?? this.matchedItem,
      candidates: candidates ?? this.candidates,
    );
  }
}
