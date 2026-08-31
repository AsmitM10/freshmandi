import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// MISSING FROM DESIGN: Sales register (counter/phone/WhatsApp sales,
/// distinct from Online Orders) was not part of this conversion pass.
class SalesScreenStub extends StatelessWidget {
  const SalesScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      body: const Center(
        child: EmptyStateView(
          icon: Icons.receipt_outlined,
          title: 'Sales register not yet converted',
          body: 'This screen exists in the approved HTML build but was out of scope for this Flutter conversion pass.',
        ),
      ),
    );
  }
}
