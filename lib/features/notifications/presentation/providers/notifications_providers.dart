import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/device_token_repository.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';
import '../../push_notification_service.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

/// autoDispose so a fresh list is fetched every time the Notifications
/// page is opened, rather than showing a stale snapshot from earlier in
/// the session.
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final restaurant = await ref.watch(currentRestaurantProvider.future);
  if (restaurant == null) return const [];
  return ref.watch(notificationsRepositoryProvider).fetchAll(restaurant.id);
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(supabaseClientProvider));
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref.watch(deviceTokenRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Watched once from MainShellScreen (mounted only once the restaurant is
/// signed in and approved) — registers this device's FCM token for
/// [restaurantId] and starts listening for foreground messages. Riverpod
/// keeps this cached per restaurantId for as long as something keeps
/// watching it, so it only actually runs `init` once per session rather
/// than on every rebuild.
final pushNotificationInitProvider = FutureProvider.autoDispose.family<void, String>((ref, restaurantId) async {
  await ref.watch(pushNotificationServiceProvider).init(restaurantId: restaurantId);
});
