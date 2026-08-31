import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import 'repository_providers.dart';

final ordersSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final ordersStatusFilterProvider = StateProvider.autoDispose<OrderStatus?>((ref) => null);

final ordersListProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  final search = ref.watch(ordersSearchProvider);
  final status = ref.watch(ordersStatusFilterProvider);
  return ref.watch(ordersRepositoryProvider).fetchAll(status: status, search: search);
});

final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).fetchById(id);
});
