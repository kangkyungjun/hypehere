// Basic Flutter widget test for MarketLens

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/main.dart';

void main() {
  testWidgets('MarketLens app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MarketLensApp());

    // Verify that bottom navigation is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify that Analysis tab is shown by default
    expect(find.text('Analysis'), findsOneWidget);
  });
}
