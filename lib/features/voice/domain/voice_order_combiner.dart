import 'parsed_voice_item.dart';

/// Sums quantities for matched items that resolved to the same real
/// catalog item — the "5 kg tomato ... 3 kg tomato" said in one order
/// becomes a single 8 kg line rather than two separate cart rows. Pulled
/// out as its own pure function (rather than inlined in the controller)
/// so it's independently testable and there's exactly one place this
/// rule is implemented.
Map<String, int> combineMatchedQuantities(List<ParsedVoiceItem> items) {
  final quantities = <String, int>{};
  for (final item in items) {
    if (item.status != VoiceMatchStatus.matched) continue;
    final id = item.matchedItem!.id;
    quantities[id] = (quantities[id] ?? 0) + item.quantity;
  }
  return quantities;
}
