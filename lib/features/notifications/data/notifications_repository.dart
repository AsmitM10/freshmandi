import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_notification.dart';

/// Reads/updates the signed-in restaurant's own notifications — RLS (see
/// 20260901000002_notifications.sql) rejects any other restaurant's rows
/// regardless of what this is asked for.
class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'invoices';

  String? _resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<List<AppNotification>> fetchAll(String restaurantId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => AppNotification.fromMap(r as Map<String, dynamic>, resolveImageUrl: _resolveImageUrl))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  /// Clears the bell badge — called once when the Notifications screen
  /// itself is opened, rather than requiring each card to be tapped
  /// individually.
  Future<void> markAllAsRead(String restaurantId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('restaurant_id', restaurantId)
        .eq('is_read', false);
  }
}
