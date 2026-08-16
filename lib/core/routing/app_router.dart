import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/status_screens.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/terms_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/items/presentation/screens/shop_screen.dart';
import '../../features/registration/presentation/screens/registration_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../constants/app_config.dart';
import '../constants/app_routes.dart';
import 'main_shell_screen.dart';
import 'router_refresh_stream.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);

  // On web (and with deep links generally), the last-visited route persists
  // in the URL across reloads — `initialLocation` only applies when there's
  // no existing URL state. Without this flag, reloading the page on e.g.
  // /welcome or /register would skip Splash's session check entirely.
  // Splash must gate every cold start, not just ones that happen to start
  // at "/splash", so the very first redirect evaluation of this router's
  // lifetime always routes through Splash first, regardless of URL.
  var hasBootstrapped = false;

  // Hard floor for the splash minimum-display duration, enforced at the
  // routing layer as a second, independent guarantee on top of the timer
  // inside SplashScreen itself: no matter what triggers a navigation
  // attempt away from /splash — a redirect re-evaluation, a stray auth
  // event, anything — the router refuses to leave /splash until this much
  // wall-clock time has passed since the router (i.e. the app) started.
  final appStartTime = DateTime.now();

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: RouterRefreshStream(client.auth.onAuthStateChange),
    redirect: (context, state) {
      if (!hasBootstrapped) {
        hasBootstrapped = true;
        if (state.matchedLocation != AppRoutes.splash) {
          return AppRoutes.splash;
        }
      }

      final elapsedSinceStart = DateTime.now().difference(appStartTime);
      if (state.matchedLocation != AppRoutes.splash &&
          elapsedSinceStart < AppConfig.splashMinDuration) {
        return AppRoutes.splash;
      }

      final hasSession = client.auth.currentSession != null;
      final isStatusGatedRoute = AppRoutes.statusGatedRoutes.contains(
        state.matchedLocation,
      );
      // Session expired/signed out while on a status-gated placeholder route
      // (e.g. pending approval) — send back to the unauthenticated root.
      if (!hasSession && isStatusGatedRoute) {
        return AppRoutes.welcome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegistrationScreen(
          termsAcceptedAt: state.extra is DateTime ? state.extra as DateTime : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountRejected,
        builder: (context, state) => const AccountRejectedScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountSuspended,
        builder: (context, state) => const AccountSuspendedScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shop,
                builder: (context, state) => const ShopScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
