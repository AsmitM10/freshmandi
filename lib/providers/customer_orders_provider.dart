import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import 'repository_providers.dart';

final customerOrdersProvider = FutureProvider.autoDispose.family<List<Order>, String>((ref, customerId) {
  return ref.watch(ordersRepositoryProvider).fetchByCustomer(customerId);
});
