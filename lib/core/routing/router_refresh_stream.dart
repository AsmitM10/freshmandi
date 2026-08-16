import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a Stream (Supabase's auth state stream) into a Listenable so
/// go_router's [GoRouter.refreshListenable] re-evaluates `redirect` whenever
/// auth state changes (sign-in, sign-out, token refresh, session expiry).
class RouterRefreshStream extends ChangeNotifier {
  RouterRefreshStream(Stream<dynamic> stream) {
    // No eager notifyListeners() here — GoRouter already resolves the
    // initial redirect chain once on construction. Firing an extra refresh
    // immediately, combined with the router's own one-time "force through
    // splash" redirect logic, was causing Splash's page to be rebuilt a
    // second time right at startup — its whole 2.5s minimum-display timer
    // ran twice back to back (~5s total) instead of once.
    // Supabase can emit more than one auth event back-to-back in the same
    // frame (e.g. SIGNED_IN immediately followed by TOKEN_REFRESHED).
    // Calling notifyListeners() synchronously from inside this stream
    // callback risks landing while GoRouter/Flutter is still mid-rebuild
    // from the first event, which throws "setState()/markNeedsBuild()
    // called during build" and can leave a "Duplicate GlobalKey" behind —
    // observed in practice as login hanging right after OTP verification.
    // Scheduling as a microtask lets the current build finish first.
    _subscription = stream.asBroadcastStream().listen((_) {
      scheduleMicrotask(notifyListeners);
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
