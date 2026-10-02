import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/models/portfolio_data.dart';
import 'package:marketlens/screens/watchlist/widgets/holding_list_item.dart';

import 'support/screen_harness.dart';

/// 보유종목 행의 **티커와 정체성 변경 표시는 잘리면 안 된다** (S6).
///
/// ## 왜 이 테스트가 따로 필요한가
///
/// 전수 스윕(`overflow_sweep_test.dart`)은 처음에 **숫자만** 잘림 검사를
/// 했다. 그래서 변경 표시를 티커와 같은 Row에 넣었을 때 둘 다 통과했는데,
/// 캡쳐를 눈으로 보니:
///
/// - `BK → ...`  — 새 티커가 잘려 화살표가 아무것도 가리키지 않았다
/// - `거래종료`만 남고 **`HOLX`가 통째로 사라졌다**
///
/// 어느 종목인지 못 읽는 건 틀린 숫자만큼 나쁘다. 스윕 쪽 검사도 넓혔지만,
/// 이 테스트는 **좁은 폭을 명시적으로 강제해서** 회귀를 직접 막는다.
void main() {
  setUpAll(() async {
    mockPlatformChannels();
    await loadAppFont();
  });

  PortfolioHolding holding({String? resolved, String? reason}) =>
      PortfolioHolding(
        ticker: 'HOLX',
        resolvedTicker: resolved,
        changeReason: reason,
        shares: 15,
        avgPrice: 81.20,
        name: '홀로직 인코퍼레이티드',
        nameKo: '홀로직 인코퍼레이티드',
        currentPrice: 76.01,
        changePct: -0.4,
        score: 48,
        signal: 'HOLD',
      );

  /// 화면을 좁게 **강제한다.** 기본 테스트 폭(800)은 너무 넉넉해서
  /// 칼럼 경쟁이 안 드러난다. 실기기 최소폭에 가깝게 320으로 좁힌다.
  ///
  /// 래핑은 캡쳐·스윕과 **같은 하네스**를 쓴다. 직접 MaterialApp을 세우면
  /// `context.mlColors`(ThemeExtension)가 없어서 위젯이 빌드조차 안 된다.
  Future<void> pumpNarrow(
    WidgetTester tester,
    PortfolioHolding h, {
    double scale = 1.3,
  }) async {
    tester.view.physicalSize = const Size(320 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ScreenHarness().app(
      HoldingListItem(holding: h, onTap: () {}, onDelete: () {}),
      dark: false,
      scale: scale,
    ));
    await tester.pump();
  }

  /// 해당 문자열의 Text가 **존재하고 잘리지 않았는지**.
  ///
  /// 존재만 보면 부족하다 — `HOLX`는 0폭으로 눌렸을 때도 트리에는 있었다.
  /// `didExceedMaxLines`까지 봐야 "읽을 수 있는가"를 검사한 것이 된다.
  void expectIntact(String text) {
    final finder = find.text(text);
    expect(finder, findsOneWidget, reason: '"$text"가 화면에 없다');
    final r = finder.evaluate().single.renderObject;
    expect(
      r is RenderParagraph && r.didExceedMaxLines,
      isFalse,
      reason: '"$text"가 잘렸다',
    );
  }

  for (final scale in [1.0, 1.3]) {
    testWidgets('개명 — 티커와 → BNY 둘 다 온전하다 (x$scale)', (tester) async {
      await pumpNarrow(tester, holding(resolved: 'BNY', reason: 'renamed'),
          scale: scale);

      expectIntact('HOLX');
      expectIntact('→ BNY');
    });

    testWidgets('상장폐지 — 티커가 칩에 밀려 사라지지 않는다 (x$scale)',
        (tester) async {
      await pumpNarrow(tester, holding(reason: 'delisted'), scale: scale);

      // 이게 실제로 났던 버그다: `거래종료`만 남고 티커가 0폭으로 눌렸다.
      expectIntact('HOLX');
      expect(find.text('거래종료'), findsOneWidget);
    });
  }

  testWidgets('변경 없는 종목에는 표시가 안 붙는다', (tester) async {
    await pumpNarrow(tester, holding());

    expectIntact('HOLX');
    expect(find.textContaining('→'), findsNothing);
    expect(find.text('거래종료'), findsNothing);
  });
}
