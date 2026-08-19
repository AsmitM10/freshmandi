import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/business_settings.dart';

/// Reads the wholesaler's single business-info row. RLS grants `select` to
/// every authenticated restaurant (it's what appears on their own
/// invoice) with no write policy at all — only a service-role/SQL-editor
/// action can ever change it (see the migration).
class BusinessSettingsRepository {
  BusinessSettingsRepository(this._client);

  final SupabaseClient _client;

  Future<BusinessSettings> fetch() async {
    try {
      final row = await _client.from('business_settings').select().limit(1).single();
      return BusinessSettings.fromMap(row);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
