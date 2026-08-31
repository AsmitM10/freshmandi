import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/dashboard_repository.dart';
import 'repository_providers.dart';

final dashboardSnapshotProvider = FutureProvider.autoDispose<DashboardSnapshot>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetch();
});
