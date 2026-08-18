import 'package:flutter_application_1/features/items/domain/catalog_item.dart';
import 'package:flutter_application_1/features/items/domain/item_category.dart';
import 'package:flutter_application_1/features/voice/domain/item_matcher.dart';
import 'package:flutter_application_1/features/voice/domain/parsed_voice_item.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogItem _item(String id, String name, {String unit = 'Kg', bool isAvailable = true}) {
  return CatalogItem(
    id: id,
    name: name,
    category: ItemCategory.indianVegetables,
    unit: unit,
    isAvailable: isAvailable,
    sortOrder: 0,
  );
}

void main() {
  const matcher = ItemMatcher();

  final catalog = [
    _item('1', 'Tomato'),
    _item('2', 'Onion'),
    _item('3', 'Carrot'),
    _item('4', 'Coriander', unit: 'Bdl'),
    _item('5', 'Coconut', unit: 'Pcs'),
    _item('6', 'Green Capsicum'),
    _item('7', 'Green Chilli'),
    _item('8', 'Brinjal'),
    _item('9', 'Discontinued Item', isAvailable: false),
  ];

  test('exact (case-insensitive) name match', () {
    final result = matcher.match('tomato', catalog);
    expect(result.status, VoiceMatchStatus.matched);
    expect(result.item!.name, 'Tomato');
  });

  test('plural spoken form matches singular catalog name', () {
    final result = matcher.match('tomatoes', catalog);
    expect(result.status, VoiceMatchStatus.matched);
    expect(result.item!.name, 'Tomato');
  });

  test('unmatched when nothing is close enough', () {
    final result = matcher.match('spaceship', catalog);
    expect(result.status, VoiceMatchStatus.unmatched);
  });

  test('ambiguous when the phrase could mean more than one real item', () {
    final result = matcher.match('green', catalog);
    expect(result.status, VoiceMatchStatus.ambiguous);
    expect(result.candidates.map((c) => c.name), containsAll(['Green Capsicum', 'Green Chilli']));
  });

  test('controlled fuzzy match tolerates a single mis-heard letter', () {
    final result = matcher.match('brinjol', catalog);
    expect(result.status, VoiceMatchStatus.matched);
    expect(result.item!.name, 'Brinjal');
  });

  test('unavailable catalog items are never matched', () {
    final result = matcher.match('discontinued item', catalog);
    expect(result.status, VoiceMatchStatus.unmatched);
  });

  test('empty phrase is unmatched, never invents an item', () {
    final result = matcher.match('', catalog);
    expect(result.status, VoiceMatchStatus.unmatched);
  });
}
