import 'package:flutter_application_1/features/items/domain/catalog_item.dart';
import 'package:flutter_application_1/features/items/domain/item_category.dart';
import 'package:flutter_application_1/features/voice/domain/parsed_voice_item.dart';
import 'package:flutter_application_1/features/voice/domain/voice_order_combiner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tomato = CatalogItem(
    id: 'tomato-1',
    name: 'Tomato',
    category: ItemCategory.indianVegetables,
    unit: 'Kg',
    isAvailable: true,
    sortOrder: 0,
  );
  final onion = CatalogItem(
    id: 'onion-1',
    name: 'Onion',
    category: ItemCategory.indianVegetables,
    unit: 'Kg',
    isAvailable: true,
    sortOrder: 1,
  );

  test('same matched item said twice in one order is summed into one line', () {
    final items = [
      ParsedVoiceItem(rawText: 'tomato', quantity: 5, status: VoiceMatchStatus.matched, matchedItem: tomato),
      ParsedVoiceItem(rawText: 'tomato', quantity: 3, status: VoiceMatchStatus.matched, matchedItem: tomato),
    ];
    final result = combineMatchedQuantities(items);
    expect(result, {'tomato-1': 8});
  });

  test('different matched items stay as separate entries', () {
    final items = [
      ParsedVoiceItem(rawText: 'tomato', quantity: 5, status: VoiceMatchStatus.matched, matchedItem: tomato),
      ParsedVoiceItem(rawText: 'onion', quantity: 2, status: VoiceMatchStatus.matched, matchedItem: onion),
    ];
    final result = combineMatchedQuantities(items);
    expect(result, {'tomato-1': 5, 'onion-1': 2});
  });

  test('unmatched and ambiguous items are excluded entirely', () {
    final items = [
      ParsedVoiceItem(rawText: 'tomato', quantity: 5, status: VoiceMatchStatus.matched, matchedItem: tomato),
      const ParsedVoiceItem(rawText: 'unknown thing', quantity: 2, status: VoiceMatchStatus.unmatched),
      ParsedVoiceItem(
        rawText: 'green',
        quantity: 1,
        status: VoiceMatchStatus.ambiguous,
        candidates: [onion],
      ),
    ];
    final result = combineMatchedQuantities(items);
    expect(result, {'tomato-1': 5});
  });
}
