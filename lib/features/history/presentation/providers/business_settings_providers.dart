import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/business_settings_repository.dart';
import '../../domain/business_settings.dart';

final businessSettingsRepositoryProvider = Provider<BusinessSettingsRepository>((ref) {
  return BusinessSettingsRepository(ref.watch(supabaseClientProvider));
});

/// The wholesaler's business info for the invoice header/footer — one row,
/// fetched once and kept alive (it changes rarely, if ever, from the
/// customer's side).
final businessSettingsProvider = FutureProvider<BusinessSettings>((ref) {
  return ref.watch(businessSettingsRepositoryProvider).fetch();
});
