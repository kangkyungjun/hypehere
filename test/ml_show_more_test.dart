import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/widgets/common/ml_show_more.dart';

/// "더보기 / 줄이기"의 동작 계약.
///
/// 개편 전 7벌 중 **4벌이 접기 불가인 단방향**이었고 라벨 소스가 5종이었다.
/// 그 두 가지가 회귀하지 않도록 못 박는다.
Widget _host(Widget child, {Locale locale = const Locale('ko')}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  theme: ThemeData(
    useMaterial3: true,
    extensions: const [MarketLensColors.light],
  ),
  home: Scaffold(body: child),
);

void main() {
  group('MlShowMoreList', () {
    Widget list({int initialCount = 3, bool collapsible = true, int n = 10}) =>
        MlShowMoreList<int>(
          items: List.generate(n, (i) => i),
          initialCount: initialCount,
          collapsible: collapsible,
          itemBuilder: (_, item, __) => Text('항목$item'),
        );

    testWidgets('처음엔 initialCount개만 보인다', (tester) async {
      await tester.pumpWidget(_host(list()));

      expect(find.text('항목0'), findsOneWidget);
      expect(find.text('항목2'), findsOneWidget);
      expect(find.text('항목3'), findsNothing);
      // 남은 개수를 라벨에 노출한다
      expect(find.textContaining('7'), findsOneWidget);
    });

    testWidgets('더보기 → 전체, 줄이기 → 원래대로 (양방향)', (tester) async {
      await tester.pumpWidget(_host(list()));

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('항목9'), findsOneWidget);

      // ★ 개편 전 4곳은 여기서 되돌릴 수 없었다.
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('항목3'), findsNothing);
    });

    testWidgets('collapsible: false — 펼친 뒤 버튼이 사라진다', (tester) async {
      await tester.pumpWidget(_host(list(collapsible: false)));

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text('항목9'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('항목이 initialCount 이하면 버튼이 없다', (tester) async {
      await tester.pumpWidget(_host(list(n: 2)));

      expect(find.text('항목1'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('MlShowMoreButton — 라벨 l10n', () {
    Widget button(Locale l, {bool expanded = false}) => _host(
      MlShowMoreButton(expanded: expanded, onPressed: () {}),
      locale: l,
    );

    testWidgets('ko — 더보기 / 줄이기', (tester) async {
      await tester.pumpWidget(button(const Locale('ko')));
      expect(find.text('더보기'), findsOneWidget);

      await tester.pumpWidget(button(const Locale('ko'), expanded: true));
      expect(find.text('줄이기'), findsOneWidget);
    });

    testWidgets('ja — 하드코딩 영어로 새지 않는다', (tester) async {
      // 개편 전 explore_screen은 ko/en 2개국어만 인라인 하드코딩이라
      // ja/zh/es 사용자에게 영어가 나왔다.
      await tester.pumpWidget(button(const Locale('ja'), expanded: true));
      expect(find.text('折りたたむ'), findsOneWidget);
    });

    testWidgets('es — 하드코딩 영어로 새지 않는다', (tester) async {
      await tester.pumpWidget(button(const Locale('es'), expanded: true));
      expect(find.text('Ver menos'), findsOneWidget);
    });
  });
}
