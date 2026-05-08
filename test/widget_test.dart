import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fx_oil_app/main.dart';

void main() {
  testWidgets('read-only paper dashboard smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GichanMockDashboardApp());
    await tester.pumpAndSettle();

    expect(find.text('Gichan Abba System'), findsOneWidget);
    expect(find.text('계좌정보'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });
}
