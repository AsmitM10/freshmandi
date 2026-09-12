import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers this device's FCM token — against a restaurant (customer
/// app) or flagged as the admin device (Business Console) — so
/// send-notification knows where to deliver each of the 4 notification
/// types. See 20260901000001_device_tokens.sql /
/// 20260901000003_notification_types.sql for the table/RLS this reads and
/// writes; a row is either a restaurant's or the admin's, never both.
class DeviceTokenRepository {
  DeviceTokenRepository(this._client);

  final SupabaseClient _client;

  Future<void> registerToken({
    String? restaurantId,
    bool isAdmin = false,
    required String token,
    required String platform,
  }) async {
    await _client.from('device_tokens').upsert({
      'restaurant_id': restaurantId,
      'is_admin': isAdmin,
      'token': token,
      'platform': platform,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }
}
