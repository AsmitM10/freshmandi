import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/admin_sales_repository.dart';

final adminSalesRepositoryProvider = Provider<AdminSalesRepository>((ref) {
  return AdminSalesRepository(ref.watch(supabaseClientProvider));
});
