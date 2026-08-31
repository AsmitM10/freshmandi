import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// MISSING FROM DESIGN: Notifications was not part of this conversion pass.
class NotificationsScreenStub extends StatelessWidget {
  const NotificationsScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: EmptyStateView(
          icon: Icons.notifications_outlined,
          title: 'Notifications not yet converted',
          body: 'This screen exists in the approved HTML build but was out of scope for this Flutter conversion pass.',
        ),
      ),
    );
  }
}
