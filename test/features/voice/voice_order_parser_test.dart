import 'package:flutter_application_1/features/voice/domain/voice_order_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = VoiceOrderParser();

  test('single item with numeral quantity and unit', () {
    final result = parser.parse('10 kg tomato');
    expect(result, hasLength(1));
    expect(result.single.quantity, 10);
    expect(result.single.nameCandidate, 'tomato');
  });

  test('two items joined by "and"', () {
    final result = parser.parse('5 kg onion and 2 kg carrot');
    expect(result, hasLength(2));
    expect(result[0].quantity, 5);
    expect(result[0].nameCandidate, 'onion');
    expect(result[1].quantity, 2);
    expect(result[1].nameCandidate, 'carrot');
  });

  test('multiple items with no connector words at all', () {
    final result = parser.parse('10 kilo tomato 5 kilo potato 2 kilo onion');
    expect(result, hasLength(3));
    expect(result[0].quantity, 10);
    expect(result[0].nameCandidate, 'tomato');
    expect(result[1].quantity, 5);
    expect(result[1].nameCandidate, 'potato');
    expect(result[2].quantity, 2);
    expect(result[2].nameCandidate, 'onion');
  });

  test('bundle unit, two items', () {
    final result = parser.parse('1 bundle coriander and 2 bundle mint');
    expect(result, hasLength(2));
    expect(result[0].quantity, 1);
    expect(result[0].nameCandidate, 'coriander');
    expect(result[1].quantity, 2);
    expect(result[1].nameCandidate, 'mint');
  });

  test('pieces unit', () {
    final result = parser.parse('3 pieces coconut');
    expect(result, hasLength(1));
    expect(result.single.quantity, 3);
    expect(result.single.nameCandidate, 'coconut');
  });

  test('duplicate item said twice stays as two separate segments (combining happens later)', () {
    final result = parser.parse('5 kg tomato and 3 kg tomato');
    expect(result, hasLength(2));
    expect(result[0].nameCandidate, 'tomato');
    expect(result[1].nameCandidate, 'tomato');
    expect(result[0].quantity, 5);
    expect(result[1].quantity, 3);
  });

  test('natural language with spelled-out numbers and filler words', () {
    final result = parser.parse('I want ten kilos of tomato and five kilos of onion');
    expect(result, hasLength(2));
    expect(result[0].quantity, 10);
    expect(result[0].nameCandidate, 'tomato');
    expect(result[1].quantity, 5);
    expect(result[1].nameCandidate, 'onion');
  });

  test('bare item name with no quantity at all defaults to quantity 1', () {
    final result = parser.parse('cauliflower');
    expect(result, hasLength(1));
    expect(result.single.quantity, 1);
    expect(result.single.nameCandidate, 'cauliflower');
  });

  test('two bare item names joined by "and" default to quantity 1 each', () {
    final result = parser.parse('cauliflower and potato');
    expect(result, hasLength(2));
    expect(result[0].quantity, 1);
    expect(result[0].nameCandidate, 'cauliflower');
    expect(result[1].quantity, 1);
    expect(result[1].nameCandidate, 'potato');
  });

  test('a mix of quantified and bare items in one sentence', () {
    final result = parser.parse('5 kg tomato and cauliflower');
    expect(result, hasLength(2));
    expect(result[0].quantity, 5);
    expect(result[0].nameCandidate, 'tomato');
    expect(result[1].quantity, 1);
    expect(result[1].nameCandidate, 'cauliflower');
  });

  test('empty transcript produces no segments', () {
    final result = parser.parse('');
    expect(result, isEmpty);
  });

  test('unit-less quantity still parses, matching resolves the unit later', () {
    final result = parser.parse('10 tomatoes');
    expect(result, hasLength(1));
    expect(result.single.quantity, 10);
    expect(result.single.nameCandidate, 'tomatoes');
  });

  test('multi-word item name is preserved', () {
    final result = parser.parse('5 kg green capsicum');
    expect(result, hasLength(1));
    expect(result.single.nameCandidate, 'green capsicum');
  });
}
