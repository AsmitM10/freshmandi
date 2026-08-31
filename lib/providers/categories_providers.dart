import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'repository_providers.dart';

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).fetchAll();
});
