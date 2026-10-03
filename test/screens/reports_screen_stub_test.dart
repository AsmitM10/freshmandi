import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/screens/reports_screen_stub.dart';

void main() {
  testWidgets('reports screen shows overview and key metrics', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportsScreenStub()));

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Sales overview'), findsOneWidget);
  });
}
