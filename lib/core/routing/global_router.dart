import 'package:go_router/go_router.dart';

/// Set once in main.dart's FreshMandiApp.build() (`globalRouter = router`)
/// so notification-tap handling — which runs from an FCM callback, not a
/// widget build, and so has no BuildContext of its own — can still
/// navigate. Safe because by the time any tap can occur the app is
/// already running and the router already built.
GoRouter? globalRouter;
