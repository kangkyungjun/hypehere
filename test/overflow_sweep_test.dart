import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/screen_harness.dart';

/// 배율 내성 전수 검사.
///
/// ## 왜 정적 분석으로는 못 잡는가
///
/// "고정 높이 박스 + 행간 미지정 텍스트" 조합이 **세 번** 터졌다 —
/// 섹터 차트 `_labelHeight`, 차트 축 라벨, 보유종목 점수 배지. 셋 다
/// 1.0배에서 멀쩡하고 **1.3배에서만** 깨진다(앱이 textScaler를 1.3까지 허용).
///
/// 정규식으로 `height: N` + 근처 `Text`를 찾아봤더니 오탐이 압도적이었다 —
/// `SizedBox(20×20, CircularProgressIndicator)` 같은 스피너가 전부 걸렸다.
/// 세 버그는 **전부 렌더해 봐서** 잡혔다. 그래서 검사도 렌더로 한다.
///
/// ## 왜 `takeException()`만으로는 부족한가
///
/// - `RenderFlex` 오버플로는 예외가 아니라 `FlutterError`로 보고된다.
/// - `TextOverflow.ellipsis`는 **아무것도 던지지 않고** 조용히 자른다.
///   숫자가 잘리면 `43,5…`처럼 **틀린 값이 표시된다**.
///
/// 캡쳐 하네스(`support/screen_harness.dart`)와 **같은 조립**을 렌더한다.
/// 따로 두면 캡쳐는 멀쩡한데 검사는 옛 화면을 보는 일이 생긴다.
void main() {
  late ScreenHarness harness;

  setUpAll(() async {
    mockPlatformChannels();
    await loadAppFont();
    harness = ScreenHarness();
  });

  /// 잘리면 **안 되는** 텍스트를 찾는다. 종목명·섹터명의 ellipsis는
  /// 의도된 동작이므로 제외한다.
  ///
  /// 두 종류를 본다:
  ///
  /// 1. **숫자** — `43,5…`처럼 잘리면 틀린 값이 표시된다.
  /// 2. **티커·정체성 변경 표시** — 숫자 검사만 있을 때 이게 빠져나갔다.
  ///    보유종목 행에 `→ BNY`를 붙였더니 `→ …`로 잘려 화살표가 아무것도
  ///    가리키지 않았고, 상장폐지 행은 `거래종료`에 밀려 **티커가 통째로
  ///    사라졌다**. 어느 종목인지 못 읽는 건 틀린 숫자만큼 나쁘다.
  ///    캡쳐를 눈으로 보고서야 발견했다 — 그래서 검사에 넣는다.
  List<String> truncatedCritical() {
    final numeric = RegExp(r'^[▲▼─+\-]?\$?[\d,.]+%?$');
    // 티커(`BRK-B`)와 변경 표시(`→ BNY`). 한글 회사명은 안 걸린다.
    final symbol = RegExp(r'^(→\s*)?[A-Z][A-Z0-9.\-]{0,7}$');
    final out = <String>[];
    for (final e in find.byType(Text).evaluate()) {
      final r = e.renderObject;
      final t = (e.widget as Text).data ?? '';
      if (r is! RenderParagraph || !r.didExceedMaxLines) continue;
      if (numeric.hasMatch(t) || symbol.hasMatch(t)) out.add(t);
    }
    return out;
  }

  // 앱은 `main.dart:197`에서 textScaler를 [0.8, 1.3]으로 클램프한다.
  // 그 경계를 그대로 검사한다.
  const scales = [0.8, 1.0, 1.3];

  for (final name in ScreenHarness().screens.keys) {
    for (final scale in scales) {
      for (final dark in [false, true]) {
        final label = '$name ${dark ? 'dark' : 'light'} x$scale';

        testWidgets('오버플로·잘림 없음 — $label', (tester) async {
          tester.view.physicalSize =
              const Size(screenW * 3, screenH * 3);
          tester.view.devicePixelRatio = 3.0;
          addTearDown(tester.view.reset);

          final errors = <FlutterErrorDetails>[];
          final previous = FlutterError.onError;
          FlutterError.onError = errors.add;
          addTearDown(() => FlutterError.onError = previous);

          await tester.pumpWidget(harness.app(
            harness.screens[name]!(),
            dark: dark,
            scale: scale,
          ));
          await tester.pump(const Duration(milliseconds: 300));

          final overflow = errors
              .map((e) => e.exception.toString())
              .where((s) => s.contains('overflowed'))
              .toList();
          expect(overflow, isEmpty, reason: '$label\n${overflow.join("\n")}');

          final cut = truncatedCritical();
          expect(cut, isEmpty, reason: '$label 잘리면 안 되는 텍스트: $cut');
        });
      }
    }
  }
}
