import 'number_words.dart';

/// One item phrase pulled out of the transcript before catalog matching —
/// just a quantity and a raw name candidate. Matching against the real
/// catalog (and resolving the final unit) happens separately in
/// [ItemMatcher]; this class only knows about words, never about Supabase.
class RawVoiceSegment {
  const RawVoiceSegment({required this.quantity, required this.nameCandidate});

  final int quantity;
  final String nameCandidate;
}

/// Turns a raw speech transcript into a list of (quantity, item-name
/// candidate) segments.
///
/// Works in two passes:
///  1. Split the transcript into clauses on real connectors (",", "and",
///     "&", "plus", "then", "also") after stripping pure noise phrases
///     ("i want", "please", "of", "the", ...) — connectors are kept as
///     clause boundaries rather than stripped, since they're the only
///     signal available for splitting a bare item name ("cauliflower and
///     potato") that has no quantity to delimit it.
///  2. Within each clause, scan for one or more (quantity, name) chunks:
///     a leading numeral or spelled-out number starts a new item and
///     consumes words up to the next such number — this is what makes
///     "10 kg tomato 5 kg onion" (a single clause, no connector at all)
///     resolve to two items. A clause with no leading quantity at all is
///     a bare item name and defaults to quantity 1, matching how someone
///     actually speaks ("cauliflower" alone means "add one cauliflower"),
///     not silently dropped.
///
/// This is a lightweight rule-based parser, not an NLP model — it covers
/// the grocery-order phrasing this feature needs to support, not
/// open-ended natural language. A clause with more than one bare item
/// name and no connector between them ("tomato onion", no "and", no
/// quantities) is a known, accepted limitation — there's no signal left
/// to split on at that point.
class VoiceOrderParser {
  const VoiceOrderParser();

  static const _unitWords = {
    'kg', 'kgs', 'kilo', 'kilos', 'kilogram', 'kilograms',
    'g', 'gm', 'gms', 'gram', 'grams',
    'piece', 'pieces', 'pc', 'pcs',
    'bundle', 'bundles', 'bdl',
    'dozen', 'dozens',
    'box', 'boxes',
    'packet', 'packets',
    'liter', 'litre', 'liters', 'litres', 'ltr',
    'bunch', 'bunches',
  };

  /// Pure noise — stripped wherever it appears. Connectors are handled
  /// separately (see [_connectorPattern]) since they double as clause
  /// boundaries rather than being discarded outright.
  static final _noisePhrases =
      [
        'i would like',
        'i will take',
        "i'll take",
        'please give me',
        'please add',
        'please get',
        'i want',
        'i need',
        'give me',
        'get me',
        'order me',
        'order',
        'add',
        'please',
        'kindly',
        'of',
        'the',
      ]..sort((a, b) => b.split(' ').length.compareTo(a.split(' ').length));

  static const _connectorPattern = r',|\band\b|&|\bplus\b|\bthen\b|\balso\b';

  List<RawVoiceSegment> parse(String transcript) {
    final cleaned = _stripNoise(transcript.toLowerCase());
    if (cleaned.trim().isEmpty) return const [];

    final clauses = cleaned
        .split(RegExp(_connectorPattern))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty);

    final segments = <RawVoiceSegment>[];
    for (final clause in clauses) {
      segments.addAll(_scanClause(_wordsOf(clause)));
    }
    return segments;
  }

  String _stripNoise(String text) {
    var result = text;
    for (final phrase in _noisePhrases) {
      result = result.replaceAll(RegExp('\\b${RegExp.escape(phrase)}\\b'), ' ');
    }
    return result;
  }

  List<String> _wordsOf(String clause) {
    return clause
        .replaceAll(RegExp(r'[^a-z0-9. ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  List<RawVoiceSegment> _scanClause(List<String> words) {
    if (words.isEmpty) return const [];

    final segments = <RawVoiceSegment>[];
    var i = 0;
    while (i < words.length) {
      final start = i;
      int quantity;
      final read = _readQuantity(words, i);
      if (read != null) {
        quantity = read.value;
        i += read.wordsConsumed;
        if (i < words.length && _unitWords.contains(words[i])) i++;
      } else {
        // No explicit quantity for this item — treat it as one, the same
        // way a restaurant owner naturally speaks a bare item name.
        quantity = 1;
      }

      final nameWords = <String>[];
      while (i < words.length && !_isQuantityStart(words[i])) {
        nameWords.add(words[i]);
        i++;
      }
      if (nameWords.isNotEmpty) {
        segments.add(RawVoiceSegment(quantity: quantity, nameCandidate: nameWords.join(' ')));
      }
      if (i == start) i++; // always make forward progress
    }
    return segments;
  }

  ({int value, int wordsConsumed})? _readQuantity(List<String> words, int index) {
    // "2.5 kg" rounds to the nearest whole unit — the cart only ever holds
    // integer quantities (see CartState), and grocery voice orders are
    // whole-unit in practice.
    final numeral = double.tryParse(words[index]);
    if (numeral != null && numeral > 0) {
      return (value: numeral.round(), wordsConsumed: 1);
    }
    final spelled = NumberWords.parseLeading(words.sublist(index));
    if (spelled != null && spelled.value > 0) {
      return (value: spelled.value, wordsConsumed: spelled.wordsConsumed);
    }
    return null;
  }

  bool _isQuantityStart(String word) {
    return double.tryParse(word) != null || NumberWords.isNumberWord(word);
  }
}
