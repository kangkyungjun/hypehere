// Repro test: tapping "Watch Ad" on the blurred PortfolioAICard should unlock
// the analysis. On the test host (not Android/iOS), RewardedAdHelper.showAd
// takes the fail-open path (onFailed -> unlock), so the button MUST unlock.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/models/portfolio_data.dart';
import 'package:marketlens/providers/portfolio_provider.dart';
import 'package:marketlens/screens/watchlist/widgets/portfolio_ai_card.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('tap Watch Ad unlocks portfolio AI analysis', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final summary = PortfolioSummary(
      date: DateTime(2026, 7, 10, 9, 30),
      aiSummary: 'TEST ANALYSIS CONTENT',
      aiRecommendations: const [],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(extensions: const [MarketLensColors.light]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioAICard(summary: summary, isAdFree: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Locked state: the "Watch Ad" button is visible.
    final watchAdBtn = find.widgetWithText(ElevatedButton, 'Watch Ad');
    expect(watchAdBtn, findsOneWidget, reason: 'should start locked/blurred');

    // Tap it.
    await tester.tap(watchAdBtn);
    await tester.pumpAndSettle();

    // Unlocked state: the "Watch Ad" button should be gone.
    expect(
      find.widgetWithText(ElevatedButton, 'Watch Ad'),
      findsNothing,
      reason: 'after tapping Watch Ad, content should unlock (button gone)',
    );
  });
}
