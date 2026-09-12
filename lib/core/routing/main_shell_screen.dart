import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../constants/app_routes.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

/// Hosts the four bottom-nav branches (Home/Shop/History/Settings) as
/// parallel navigation stacks via go_router's StatefulShellRoute, plus the
/// floating voice button on top, which pushes the real Voice Order screen.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only reached once the restaurant is signed in and approved (this
    // shell sits behind that gate in app_router.dart), so a restaurant id
    // is always available here — registers this device for the "order
    // accepted" push the moment the signed-in restaurant reaches the main
    // app, same lifetime as the session itself.
    final restaurant = ref.watch(currentRestaurantProvider).valueOrNull;
    if (restaurant != null) {
      ref.watch(pushNotificationInitProvider(restaurant.id));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTabSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              onVoiceTapped: () => context.push(AppRoutes.voiceOrder),
            ),
          ),
        ],
      ),
    );
  }
}
