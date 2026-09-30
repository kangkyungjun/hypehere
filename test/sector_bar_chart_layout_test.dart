import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/treemap_data.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/widgets/dashboard/sector_bar_chart_widget.dart';

/// 섹터 막대차트의 **배율 내성** 계약.
///
/// 이 위젯은 `_labelHeight`/`_nameHeight`를 고정 px로 들고 있었다. 1.0배에서는
/// 맞지만 접근성 확대(앱 상한 1.3배)에서 텍스트가 박스를 넘고, 넘친 만큼 막대
/// 영역이 밀려 **막대가 섹터명 위로 번졌다.** 1.0배 스크린샷만 보면 절대 안 잡힌다.
///
/// 개편 전에도 `_nameHeight = 28`은 1.3배에서 이미 넘치고 있었다
/// (micro 10 × 1.3 × 1.15 × 2줄 = 29.9 > 28).
void main() {
  setUpAll(() async {
    final loader = FontLoader('Pretendard');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(Future.value(ByteData.view(
        File('assets/fonts/Pretendard-$w.otf').readAsBytesSync().buffer,
      )));
    }
    await loader.load();
  });

  // 캡쳐와 같은 최악 케이스: 긴 영문 섹터명 7개, 양수 2 / 음수 5.
  final sectors = [
    ('Health Care', 0.4),
    ('Consumer Staples', 0.2),
    ('Energy', -0.9),
    ('Industrials', -1.1),
    ('Real Estate', -1.2),
    ('Communication Services', -1.3),
    ('Consumer Discretionary', -1.4),
  ]
      .map((e) => TreemapSector(
            sector: e.$1,
            tickerCount: 30,
            avgChangePct: e.$2,
            items: const [],
          ))
      .toList();

  Widget harness(double scale, {List<TreemapSector>? data}) => MaterialApp(
        theme: ThemeData(
          fontFamily: 'Pretendard',
          extensions: const [MarketLensColors.light],
        ),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 370, // 402pt − 좌우 패딩 32
                child: SectorBarChartWidget(
                  sectors: data ?? sectors,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

  for (final scale in [0.8, 1.0, 1.3]) {
    testWidgets('오버플로 없음 — textScaler $scale', (tester) async {
      await tester.pumpWidget(harness(scale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // RenderFlex 오버플로는 예외가 아니라 FlutterError로 보고되므로
      // 별도로 확인한다.
      final overflowed = <String>[];
      for (final e in find.byType(Text).evaluate()) {
        final r = e.renderObject;
        if (r is RenderParagraph && r.size.height > r.constraints.maxHeight) {
          overflowed.add((e.widget as Text).data ?? '?');
        }
      }
      expect(overflowed, isEmpty, reason: '박스를 넘은 텍스트: $overflowed');
    });
  }

  testWidgets('차트 높이가 배율에 따라 커진다 (고정 px 회귀 방지)', (tester) async {
    double chartHeight(WidgetTester t) {
      // 막대 영역을 감싸는 SizedBox — Stack을 자식으로 갖는 유일한 것.
      final box = t.widget<SizedBox>(
        find.ancestor(of: find.byType(Stack), matching: find.byType(SizedBox)).first,
      );
      return box.height!;
    }

    await tester.pumpWidget(harness(1.0));
    final h10 = chartHeight(tester);

    await tester.pumpWidget(harness(1.3));
    await tester.pumpAndSettle();
    final h13 = chartHeight(tester);

    expect(
      h13,
      greaterThan(h10),
      reason: '배율이 올라가도 높이가 그대로면 텍스트가 막대 영역을 밀어낸다',
    );
  });

  testWidgets('데이터가 비어도 깨지지 않는다', (tester) async {
    await tester.pumpWidget(harness(1.3, data: const []));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
