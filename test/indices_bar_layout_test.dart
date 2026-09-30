import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/indices_data.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/theme/app_typography.dart';
import 'package:marketlens/widgets/dashboard/indices_bar_widget.dart';

/// 홈 히어로 계약.
///
/// 개편 전에는 히어로가 `isSelected ? priceLarge : priceCard` 분기 뒤에 있었고
/// `_selectedIndex`가 초기화 없는 null이라 **기본 화면에서 한 번도 렌더되지
/// 않았다.** 눈으로는 안 잡힌다(지수를 한 번 탭하면 보이므로). 테스트로 못 박는다.
///
/// 사용자가 금지한 회귀(글자 어긋남·화면 밖 이탈)도 같이 막는다 — 앱은
/// `textScaler`를 [0.8, 1.3]으로 클램프하므로 **1.3배에서 넘치지 않아야** 한다.
void main() {
  // ⚠️ 테스트 기본 폰트는 모든 글리프가 fontSize 폭의 정사각형이라 숫자 폭이
  // 실제의 1.8배로 측정된다. 폭 예산을 검증하려면 **앱이 번들하는 폰트**를
  // 그대로 써야 한다.
  setUpAll(() async {
    final loader = FontLoader('Pretendard');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(
        Future.value(
          ByteData.view(
            File('assets/fonts/Pretendard-$w.otf').readAsBytesSync().buffer,
          ),
        ),
      );
    }
    await loader.load();
  });

  MarketIndexData idx(String code, String name, double close, double pct) {
    return MarketIndexData(
      code: code,
      name: name,
      close: close,
      prevClose: close - 1,
      change: 1,
      changePct: pct,
      chart: [
        for (var i = 0; i < 30; i++)
          IndexChartPoint(date: '2026-09-${i + 1}', close: close + i % 5),
      ],
    );
  }

  // 실제 값 폭을 재현한다 — 6자리가 히어로 폭 예산의 최악 케이스다.
  final data = MarketIndicesData(
    date: '2026-09-30',
    indices: [
      idx('DIA', 'Dow Jones', 43535.06, -0.03),
      idx('QQQ', 'NASDAQ 100', 20716.43, -0.65),
      idx('SPY', 'S&P 500', 6769.35, -0.23),
    ],
  );

  Widget harness({required double scale, String? selected}) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Pretendard',
        extensions: const [MarketLensColors.light],
      ),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          // iPhone 16 Pro 논리폭 402 − 좌우 화면 패딩 32.
          body: Center(
            child: SizedBox(
              width: 370,
              child: IndicesBarWidget(data: data, selectedIndex: selected),
            ),
          ),
        ),
      ),
    );
  }

  double fontSizeOf(WidgetTester tester, String text) {
    final widget = tester.widget<Text>(find.text(text));
    return widget.style!.fontSize!;
  }

  testWidgets('히어로는 선택 없이도 렌더된다 — priceHero(37)', (tester) async {
    await tester.pumpWidget(harness(scale: 1.0));

    // S&P 500이 벤치마크라 리드로 승격된다(리스트 순서상 3번째인데도).
    expect(fontSizeOf(tester, '6,769'), AppTypography.heroMedium);

    // 나머지 둘은 보조 크기.
    expect(fontSizeOf(tester, '43,535'), AppTypography.displayMedium);
    expect(fontSizeOf(tester, '20,716'), AppTypography.displayMedium);
  });

  testWidgets('히어로 비가 게이트(≥2.5)를 넘는다', (tester) async {
    await tester.pumpWidget(harness(scale: 1.0));
    final hero = fontSizeOf(tester, '6,769');
    // 본문 기준선은 bodyMedium(14).
    expect(hero / AppTypography.bodyMedium, greaterThanOrEqualTo(2.5));
  });

  testWidgets('선택은 크기를 바꾸지 않는다 — 필터 신호일 뿐', (tester) async {
    await tester.pumpWidget(harness(scale: 1.0, selected: 'DOW30'));
    // Dow를 선택해도 히어로는 여전히 S&P다(선택 ≠ 히어로).
    expect(fontSizeOf(tester, '6,769'), AppTypography.heroMedium);
    expect(fontSizeOf(tester, '43,535'), AppTypography.displayMedium);
  });

  /// `TextOverflow.ellipsis`는 **예외를 던지지 않는다.** 폭이 모자라면 조용히
  /// `43,5…`로 잘려서 **틀린 숫자가 표시된다** — 예외 검사만으로는 못 잡는다.
  /// 지수명은 ellipsis가 **의도된 동작**이다(`NASDAQ 100` → `NASDAQ…`).
  /// 하지만 숫자가 잘리면 `43,5…`처럼 **틀린 값이 표시된다** — 이건 금지다.
  void expectNoNumberTruncation(WidgetTester tester) {
    final numeric = RegExp(r'^[▲▼─+\-]?[\d,.]+%?$');
    final truncated = <String>[];
    for (final e in find.byType(Text).evaluate()) {
      final para = e.renderObject;
      final text = (e.widget as Text).data ?? '';
      if (para is RenderParagraph &&
          para.didExceedMaxLines &&
          numeric.hasMatch(text)) {
        truncated.add(text);
      }
    }
    expect(truncated, isEmpty, reason: '잘린 숫자: $truncated');
  }

  for (final scale in [0.8, 1.0, 1.3]) {
    testWidgets('오버플로·잘림 없음 — textScaler $scale', (tester) async {
      await tester.pumpWidget(harness(scale: scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expectNoNumberTruncation(tester);
    });

    testWidgets('S&P 부재 시 5자리 지수가 리드여도 안 잘린다 — x$scale', (tester) async {
      // 최악 케이스: 벤치마크가 없어 Dow(5자리)가 히어로로 승격.
      final noSp = MarketIndicesData(
        date: '2026-09-30',
        indices: [
          idx('DIA', 'Dow Jones', 43535.06, -0.03),
          idx('QQQ', 'NASDAQ 100', 20716.43, -0.65),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: 'Pretendard',
            extensions: const [MarketLensColors.light],
          ),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 370,
                  child: IndicesBarWidget(data: noSp),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expectNoNumberTruncation(tester);
      expect(fontSizeOf(tester, '43,535'), AppTypography.heroMedium);
    });
  }

  testWidgets('지수가 1개뿐이어도 깨지지 않는다', (tester) async {
    final single = MarketIndicesData(
      date: '2026-09-30',
      indices: [idx('SPY', 'S&P 500', 6769.35, 0.4)],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'Pretendard',
          extensions: const [MarketLensColors.light],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 370, child: IndicesBarWidget(data: single)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(fontSizeOf(tester, '6,769'), AppTypography.heroMedium);
  });
}
