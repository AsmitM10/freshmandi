/// Route path constants. Wired into go_router in Phase C — declared now so
/// the route names are the single source of truth from the start.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String terms = '/terms';
  static const String register = '/register';
  static const String login = '/login';

  // Not visually defined by Figma (see PHASE C notes). Minimal, clearly
  // temporary placeholder destinations for testing the auth flow end-to-end.
  static const String pendingApproval = '/pending-approval';
  static const String accountRejected = '/account-rejected';
  static const String accountSuspended = '/account-suspended';

  // Main app shell (Phase 3+) — the real "approved" destination, replacing
  // the Phase 1 placeholder screen.
  static const String home = '/home';
  static const String shop = '/shop';
  static const String history = '/history';
  static const String settings = '/settings';

  static const Set<String> statusGatedRoutes = {
    pendingApproval,
    accountRejected,
    accountSuspended,
    home,
    shop,
    history,
    settings,
  };
}
