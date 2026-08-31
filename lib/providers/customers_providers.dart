import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import 'repository_providers.dart';

final customersSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final allCustomersProvider = FutureProvider.autoDispose<List<Customer>>((ref) {
  return ref.watch(customersRepositoryProvider).fetchAll();
});

final filteredCustomersProvider = Provider.autoDispose<AsyncValue<List<Customer>>>((ref) {
  final customersAsync = ref.watch(allCustomersProvider);
  final search = ref.watch(customersSearchProvider).trim().toLowerCase();

  return customersAsync.whenData((list) {
    if (search.isEmpty) return list;
    return list
        .where((c) =>
            c.businessName.toLowerCase().contains(search) ||
            c.contactName.toLowerCase().contains(search) ||
            c.phone.contains(search))
        .toList();
  });
});

final customerDetailProvider = FutureProvider.autoDispose.family<Customer, String>((ref, id) {
  return ref.watch(customersRepositoryProvider).fetchById(id);
});
