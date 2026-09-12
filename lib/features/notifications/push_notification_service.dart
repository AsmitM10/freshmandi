import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/routing/global_router.dart';
import '../../core/utils/root_messenger.dart';
import 'data/device_token_repository.dart';

bool get supportsPushNotifications =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Where a tapped notification's `{type, order_id}` data payload sends the
/// user — `order_request` is the only admin-facing type (an admin order
/// list entry lives at /admin/orders/:id), the other 3 (order_accepted,
/// payment, invoice) all reuse the same customer order-detail/invoice
/// screen, exactly as the existing app already shows that data — no
/// separate invoice/payment screen exists or is being created for this.
void navigateFromNotificationData(Map<String, dynamic> data) {
  final orderId = data['order_id'] as String?;
  if (orderId == null || orderId.isEmpty) return;
  final type = data['type'] as String?;
  final path = type == 'order_request' ? '/admin/orders/$orderId' : '/history/order/$orderId';
  globalRouter?.push(path);
}

/// Sets up notification-TAP handling — account-agnostic (routes purely
/// off the payload's `type`), so called exactly once at app startup
/// regardless of whether the signed-in account turns out to be the admin
/// or a restaurant. Separate from [PushNotificationService.init], which
/// is the per-account token registration + foreground banner and is
/// watched per restaurant/admin session instead.
Future<void> setupNotificationTapHandling() async {
  if (!supportsPushNotifications) return;

  // App was fully closed and got launched BY tapping a notification.
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => navigateFromNotificationData(initialMessage.data));
  }

  // App was backgrounded (not closed) and got brought forward by a tap.
  FirebaseMessaging.onMessageOpenedApp.listen((message) => navigateFromNotificationData(message.data));
}

/// Registers this device for push and shows an in-app banner for
/// messages that arrive while the app is open (FCM does NOT show its own
/// system notification in that case — only when backgrounded/terminated,
/// which the OS handles automatically with no code needed here).
class PushNotificationService {
  PushNotificationService(this._repository);

  final DeviceTokenRepository _repository;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Exactly one of [restaurantId] / [isAdmin] should be set — matches
  /// device_tokens' own ownership constraint (see
  /// 20260901000003_notification_types.sql).
  Future<void> init({String? restaurantId, bool isAdmin = false}) async {
    // No Firebase app exists for web/desktop (see firebase_options.dart) —
    // Firebase.initializeApp() was never called there, so any
    // FirebaseMessaging call here would throw.
    if (!supportsPushNotifications) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _register(restaurantId: restaurantId, isAdmin: isAdmin, token: token);
    }

    unawaited(_tokenRefreshSub?.cancel());
    _tokenRefreshSub = messaging.onTokenRefresh
        .listen((newToken) => _register(restaurantId: restaurantId, isAdmin: isAdmin, token: newToken));

    unawaited(_foregroundSub?.cancel());
    _foregroundSub = FirebaseMessaging.onMessage.listen(_showForegroundBanner);
  }

  Future<void> _register({String? restaurantId, required bool isAdmin, required String token}) {
    return _repository.registerToken(
      restaurantId: restaurantId,
      isAdmin: isAdmin,
      token: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );
  }

  void _showForegroundBanner(RemoteMessage message) {
    final title = message.notification?.title;
    final body = message.notification?.body;
    final text = [title, body].whereType<String>().join(' — ');
    if (text.isEmpty) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'View', onPressed: () => navigateFromNotificationData(message.data)),
      ),
    );
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
  }
}
