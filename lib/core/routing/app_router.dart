import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/status_screens.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/terms_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/history/presentation/screens/order_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/items/presentation/screens/shop_screen.dart';
import '../../features/orders/presentation/screens/cart_screen.dart';
import '../../features/orders/presentation/screens/order_failure_screen.dart';
import '../../features/orders/presentation/screens/order_success_screen.dart';
import '../../features/settings/presentation/screens/about_us_screen.dart';
import '../../features/settings/presentation/screens/business_details_screen.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/contact_us_screen.dart';
import '../../features/settings/presentation/screens/edit_details_screen.dart';
import '../../features/settings/presentation/screens/language_screen.dart';
import '../../features/settings/presentation/screens/return_order_screen.dart';
import '../../features/voice/presentation/screens/voice_order_screen.dart';
import '../../features/registration/presentation/screens/registration_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';
import '../../screens/customers/customers_list_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/items/items_screen.dart';
import '../../screens/notifications_screen_stub.dart';
import '../../screens/orders/order_detail_screen.dart' as admin;
import '../../screens/orders/orders_list_screen.dart';
import '../../screens/reports_screen_stub.dart';
import '../../screens/sales_screen_stub.dart';
import '../../screens/settings/settings_screen.dart' as admin;
import '../../screens/transactions/transactions_screen.dart';
import '../../widgets/app_shell.dart';
import '../constants/app_config.dart';
import '../constants/app_routes.dart';
import '../theme/app_theme.dart';
import 'main_shell_screen.dart';
import 'router_refresh_stream.dart';

/// Wraps a Business Console (admin app) screen in its own ThemeData —
/// applied only to this route subtree via a `Theme` override, so the
/// restaurant-facing app's MaterialApp theme (AppTheme.theme) is
/// unaffected everywhere else.
Widget _admin(Widget child) => Theme(data: AppTheme.light, child: child);

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
          termsAcceptedAt: state.extra is DateTime
              ? state.extra as DateTime
              : null,
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
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.orderSuccess}/:orderId',
        builder: (context, state) =>
            OrderSuccessScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.orderFailure,
        builder: (context, state) => OrderFailureScreen(
          message: state.extra is String
              ? state.extra as String
              : 'Something went wrong. Please try again.',
        ),
      ),
      GoRoute(
        path: AppRoutes.businessDetails,
        builder: (context, state) => const BusinessDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editDetails,
        builder: (context, state) => const EditDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsView,
        builder: (context, state) =>
            const TermsAndConditionsScreen(readOnly: true),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.aboutUs,
        builder: (context, state) => const AboutUsScreen(),
      ),
      GoRoute(
        path: AppRoutes.returnOrder,
        builder: (context, state) => const ReturnOrderScreen(),
      ),
      GoRoute(
        path: AppRoutes.voiceOrder,
        builder: (context, state) => const VoiceOrderScreen(),
      ),
      // Business Console (admin app) — own bottom-nav shell (Home/Orders/
      // Items/Customers/Money), reached only via the same admin-detected
      // login above. Every screen renders through `_admin(...)`, which
      // applies AppTheme.light (the Business Console's own design system)
      // to just this subtree.
      ShellRoute(
        builder: (context, state, child) => _admin(AppShell(child: child)),
        routes: [
          GoRoute(
            path: AppRoutes.adminHome,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminOrders,
            builder: (context, state) => const OrdersListScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminItems,
            builder: (context, state) => const ItemsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminCustomers,
            builder: (context, state) => const CustomersListScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminTransactions,
            builder: (context, state) => const TransactionsScreen(),
          ),
        ],
      ),
      // Detail / "More" destinations — pushed outside the shell (own back
      // button, no bottom nav), same pattern as the restaurant app below.
      GoRoute(
        path: '${AppRoutes.adminOrders}/:id',
        builder: (context, state) => _admin(
          admin.OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.adminCustomers}/:id',
        builder: (context, state) => _admin(
          CustomerDetailScreen(customerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => _admin(const admin.SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => _admin(const ReportsScreenStub()),
      ),
      GoRoute(
        path: AppRoutes.adminSales,
        builder: (context, state) => _admin(const SalesScreenStub()),
      ),
      GoRoute(
        path: AppRoutes.adminNotifications,
        builder: (context, state) => _admin(const NotificationsScreenStub()),
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
                routes: [
                  GoRoute(
                    path: 'order/:orderId',
                    builder: (context, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
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
