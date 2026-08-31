import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// MISSING FROM DESIGN: Reports was not part of this conversion pass —
/// the HTML build's Sales/Orders/Customers/Products report tabs were not
/// ported to Flutter/Supabase queries. This stub exists so the route and
/// nav entry aren't dead ends; replace it with the real screen when
/// reports are in scope for this phase.
class ReportsScreenStub extends StatelessWidget {
  const ReportsScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(
        child: EmptyStateView(
          icon: Icons.bar_chart_outlined,
          title: 'Reports not yet converted',
          body: 'This screen exists in the approved HTML build but was out of scope for this Flutter conversion pass.',
        ),
      ),
    );
  }
}
