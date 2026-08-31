// Basic Flutter widget test for MarketLens

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/main.dart';
import 'package:marketlens/providers/auth_provider.dart';
import 'package:marketlens/providers/chat_provider.dart';
import 'package:marketlens/providers/coach_mark_provider.dart';
import 'package:marketlens/providers/investment_profile_provider.dart';
import 'package:marketlens/providers/locale_provider.dart';
import 'package:marketlens/providers/portfolio_provider.dart';
import 'package:marketlens/providers/recent_search_provider.dart';
import 'package:marketlens/providers/recommendation_provider.dart';
import 'package:marketlens/providers/subscription_provider.dart';
import 'package:marketlens/providers/watchlist_provider.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MarketLens app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8000\n');

    // Build the app shell and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WatchlistProvider()),
          ChangeNotifierProvider(create: (_) => RecentSearchProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => PortfolioProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (_) => CoachMarkProvider()),
          // main.dart가 등록하는 10개와 **같은 집합**이어야 한다.
          // 이 셋이 빠져 있어 MainNavigationScreen이
          // ProviderNotFoundException으로 죽고 있었다(2026-08-15부터).
          ChangeNotifierProvider(create: (_) => InvestmentProfileProvider()),
          ChangeNotifierProvider(create: (_) => RecommendationProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(extensions: const [MarketLensColors.light]),
          home: const MainNavigationScreen(),
        ),
      ),
    );

    // Verify that the custom bottom navigation is present.
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    // Verify that the app shell is shown by default.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
