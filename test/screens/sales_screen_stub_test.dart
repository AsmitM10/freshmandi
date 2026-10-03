import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/screens/sales_screen_stub.dart';

void main() {
  testWidgets('sales register screen shows key sales data', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SalesScreenStub()));

    expect(find.text('Sales register'), findsOneWidget);
    expect(find.text('Walk-in sales'), findsWidgets);
  });
}
