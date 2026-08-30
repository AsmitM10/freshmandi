import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../domain/account_status.dart';
import '../providers/auth_providers.dart';

/// Visual design is unchanged from the original prototype. Navigation is
/// no longer a hardcoded timer to Welcome — it resolves the real Supabase
/// session + restaurant account_status, falling back to Welcome on any
/// ambiguity (no session, no restaurant row, or a lookup error).
///
/// Timing: the session/status check and the minimum display timer run
/// concurrently (`Future.wait`), and navigation only fires once BOTH are
/// done — so a fast session check never cuts the splash short, and a slow
/// one never extends it beyond however long it actually takes. There is
/// exactly one navigation call in this widget (`context.go` below), and
/// it uses `.go()` rather than `.push()` so `/splash` is replaced, not
/// stacked — back navigation can never return to it. `_hasNavigated`
/// guards against a second call firing (e.g. from a stray auth event)
/// after the first has already gone through.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  // TEMPORARY debug instrumentation — remove once timing is confirmed.
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    debugPrint(
      '[SPLASH] initialized: ${DateTime.now().toIso8601String()} (instance=$hashCode)',
    );
    debugPrint('[SPLASH] 3-second timer started');
    _resolveAndNavigate();
  }

  @override
  void dispose() {
    debugPrint(
      '[SPLASH] disposed (instance=$hashCode) at elapsed=${_stopwatch.elapsedMilliseconds}ms, hasNavigated=$_hasNavigated',
    );
    super.dispose();
  }

  Future<void> _resolveAndNavigate() async {
    final timer = Future<void>.delayed(AppConfig.splashMinDuration).then((_) {
      debugPrint(
        '[SPLASH] minimum duration completed at elapsed=${_stopwatch.elapsedMilliseconds}ms',
      );
    });

    debugPrint('[SPLASH] auth resolution started');
    final destinationFuture = _resolveDestination().then((dest) {
      debugPrint(
        '[SPLASH] auth resolution completed at elapsed=${_stopwatch.elapsedMilliseconds}ms -> $dest',
      );
      return dest;
    });

    final results = await Future.wait([timer, destinationFuture]);
    final destination = results[1] as String;

    if (!mounted || _hasNavigated) {
      debugPrint(
        '[SPLASH] navigation skipped (mounted=$mounted, hasNavigated=$_hasNavigated) at elapsed=${_stopwatch.elapsedMilliseconds}ms',
      );
      return;
    }
    _hasNavigated = true;
    debugPrint(
      '[SPLASH] navigating to: $destination | elapsed=${_stopwatch.elapsedMilliseconds}ms',
    );
    context.go(destination);
  }

  Future<String> _resolveDestination() async {
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) return AppRoutes.welcome;

    try {
      final isAdmin = await ref.read(authRepositoryProvider).isAdmin();
      if (isAdmin) return AppRoutes.adminHome;
    } catch (_) {
      // Couldn't verify admin status — fall through to the restaurant
      // check rather than failing the whole resolution.
    }

    try {
      final restaurant = await ref.read(currentRestaurantProvider.future);
      if (restaurant == null) {
        // Signed in but registration was never completed — treat as
        // unauthenticated rather than guessing a destination.
        return AppRoutes.welcome;
      }
      return restaurant.accountStatus.destinationRoute;
    } catch (_) {
      // Couldn't verify status (e.g. offline) — fail safe to the
      // unauthenticated root instead of assuming access.
      return AppRoutes.welcome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/freshmandi_logo.png',
                  width: 261,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Fresh',
                            style: TextStyle(
                              color: const Color(0xFF242424),
                              fontSize: 48,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: 'Mandi',
                            style: TextStyle(
                              color: const Color(0xFF4A8754),
                              fontSize: 48,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where Freshness Meets Business',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF242424),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
                const SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xff4F8F5B),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Loading fresh goodness',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF242424),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
