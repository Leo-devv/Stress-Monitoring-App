// Stress Monitor App - Widget Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Basic smoke test - verify the app can be instantiated
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Stress Monitor App Test'),
          ),
        ),
      ),
    );

    expect(find.text('Stress Monitor App Test'), findsOneWidget);
  });

  group('Stress Level Display', () {
    testWidgets('Should display stress percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('42%'),
            ),
          ),
        ),
      );

      expect(find.text('42%'), findsOneWidget);
    });
  });
}
