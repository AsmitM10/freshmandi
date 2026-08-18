/// Converts spelled-out English quantities ("ten", "twenty five") into
/// integers, so "I want ten kilos of tomato" parses the same as "10 kg
/// tomato". Deliberately small and grocery-order-scoped (0-999, whole
/// numbers only) rather than a general number-parsing library — nobody
/// orders "two point five thousand kilo tomato" over voice.
class NumberWords {
  NumberWords._();

  static const Map<String, int> _units = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
    'eighteen': 18, 'nineteen': 19,
    // "a dozen tomato" / "a kg tomato" — treated as quantity 1 when used as
    // a bare article immediately before a number word never occurs, but a
    // lone "a"/"an" before a unit ("a kg tomato") should still mean one.
    'a': 1, 'an': 1,
  };

  static const Map<String, int> _tens = {
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
    'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  /// True if [word] is part of a spelled-out number (so the caller knows
  /// to keep consuming words into [parsePhrase]).
  static bool isNumberWord(String word) {
    final w = word.toLowerCase();
    return _units.containsKey(w) || _tens.containsKey(w) || w == 'hundred';
  }

  /// Consumes as many leading number-words from [words] as form one
  /// number (e.g. ["twenty", "five", "kg", ...] -> 25, consuming 2 words),
  /// returning the parsed value and how many words it consumed. Returns
  /// null if [words] doesn't start with a number word at all.
  static ({int value, int wordsConsumed})? parseLeading(List<String> words) {
    if (words.isEmpty || !isNumberWord(words.first)) return null;

    var total = 0;
    var current = 0;
    var consumed = 0;
    for (final raw in words) {
      final w = raw.toLowerCase();
      if (_units.containsKey(w)) {
        current += _units[w]!;
      } else if (_tens.containsKey(w)) {
        current += _tens[w]!;
      } else if (w == 'hundred') {
        current = (current == 0 ? 1 : current) * 100;
      } else {
        break;
      }
      consumed++;
    }
    total += current;
    if (consumed == 0) return null;
    return (value: total, wordsConsumed: consumed);
  }
}
