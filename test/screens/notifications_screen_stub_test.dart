import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/screens/notifications_screen_stub.dart';

void main() {
  testWidgets('admin notifications screen shows key notification sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreenStub()));

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('System updates'), findsOneWidget);
  });
}
