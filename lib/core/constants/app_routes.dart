/// Route path constants. Wired into go_router in Phase C — declared now so
/// the route names are the single source of truth from the start.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String terms = '/terms';

  // Same screen as [terms] (read-only mode) — reached from Settings by an
  // already-registered user revisiting what they agreed to.
  static const String termsView = '/terms-view';
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

  // Pushed outside the bottom-nav shell (own back button + voice icon in
  // its header, no bottom nav bar), per the Figma reference.
  static const String cart = '/cart';

  // Shown once, right after a successful Place Order — also outside the
  // shell (own back button, no bottom nav).
  static const String orderSuccess = '/order-success';

  // Shown when Place Order fails (network/server error) — same shell-less
  // treatment; the error message is passed via `extra`, not the URL.
  static const String orderFailure = '/order-failure';

  // Reached from Settings — same shell-less treatment (own back button).
  static const String businessDetails = '/business-details';
  static const String privacyPolicy = '/privacy-policy';
  static const String aboutUs = '/about-us';
  static const String returnOrder = '/return-order';
  static const String voiceOrder = '/voice-order';

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
