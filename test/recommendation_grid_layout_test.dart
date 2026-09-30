import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/models/treemap_data.dart';
import 'package:marketlens/widgets/dashboard/recommendation_grid.dart';

/// 추천 그리드의 **고정 높이 예산** 계약.
///
/// `mainAxisExtent: 150`은 자기 주석에 "티커 18 기준, 1.3×에서 147, 여유 3px"
/// 이라 적혀 있었으나 **코드는 계속 16이었다**(`git log -L`로 확인). 16→18로
/// 예산을 실제로 쓰게 되면 여유가 3px까지 줄어든다 — 앱은 `textScaler`를
/// 1.3까지 허용하므로 여기서 넘치면 사용자가 노란 줄무늬를 본다.
void main() {
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

  Widget harness(double scale, List<TreemapItem> items) {
    return MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
              child: RecommendationGrid(items: items, onTickerTap: (_) {}),
            ),
          ),
        ),
      ),
    );
  }

  // 긴 한글명 + 5자리 가격 + 긴 티커 = 카드 폭·높이 양쪽의 최악 케이스.
  final items = [
    TreemapItem(
      ticker: 'PANW',
      nameKo: '팔로알토 네트웍스',
      score: 71,
      close: 392.09,
      changePct: -1.23,
    ),
    TreemapItem(
      ticker: 'GOOGL',
      nameKo: '알파벳 클래스 A 보통주',
      score: 66,
      close: 19199.39,
      changePct: 2.5,
    ),
  ];

  for (final scale in [0.8, 1.0, 1.3]) {
    testWidgets('고정 높이 150 안에서 넘치지 않는다 — textScaler $scale', (tester) async {
      await tester.pumpWidget(harness(scale, items));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final numeric = RegExp(r'^[▲▼─+\-]?\$?[\d,.]+%?$');
      final cut = <String>[];
      for (final e in find.byType(Text).evaluate()) {
        final r = e.renderObject;
        final t = (e.widget as Text).data ?? '';
        if (r is RenderParagraph &&
            r.didExceedMaxLines &&
            numeric.hasMatch(t)) {
          cut.add(t);
        }
      }
      // 종목명은 ellipsis가 의도된 동작이지만, **숫자가 잘리면 틀린 값**이다.
      expect(cut, isEmpty, reason: '잘린 숫자: $cut');
    });
  }
}
