import 'package:flutter_application_1/features/orders/presentation/providers/cart_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('addQuantities merges onto an existing cart instead of replacing it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).increment('tomato-1');
    container.read(cartProvider.notifier).increment('tomato-1');
    container.read(cartProvider.notifier).increment('tomato-1');
    container.read(cartProvider.notifier).increment('tomato-1');
    container.read(cartProvider.notifier).increment('tomato-1'); // tomato-1 -> 5

    container.read(cartProvider.notifier).addQuantities({'tomato-1': 3, 'onion-1': 2});

    final state = container.read(cartProvider);
    expect(state.quantityOf('tomato-1'), 8); // 5 existing + 3 from voice order
    expect(state.quantityOf('onion-1'), 2);
  });

  test('addQuantities ignores zero/negative entries', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).addQuantities({'tomato-1': 0, 'onion-1': -1, 'carrot-1': 4});

    final state = container.read(cartProvider);
    expect(state.quantityOf('tomato-1'), 0);
    expect(state.quantityOf('onion-1'), 0);
    expect(state.quantityOf('carrot-1'), 4);
  });
}
