import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:marketlens/main.dart' as app;

/// 앱스토어 제출용 스크린샷 자동 캡처.
///
/// 시뮬레이터에서 **실제 앱을 조작해** 각 화면을 찍는다. 목데이터가 아니라
/// 실서버 데이터를 쓰므로 심사에 제출 가능한 화면이 나온다.
///
/// ```
/// flutter drive \
///   --driver=test_driver/screenshot_driver.dart \
///   --target=integration_test/screenshot_test.dart \
///   -d <simulator-udid>
/// ```
/// 결과: `fastlane/screenshots/_raw/<이름>.png` (프레임 미적용)
///
/// ## 화면 선정 원칙
/// **로그인 없이 보이는 화면만** 쓴다. 관심종목·보유종목 탭은 비로그인 시
/// "로그인하여 포트폴리오를 관리하세요" 안내만 나오므로 제외했다.
/// (로그인된 시뮬레이터에서 다시 찍으면 그 두 화면도 넣을 수 있다.)
///
/// ## ⚠️ AI 탭은 반드시 마지막
/// AI 분석 서브탭에서는 `main.dart`가 **풀 탭바를 접이식 원형 버튼으로 교체**한다
/// (`aiChatSubTabActive`). 그래서 AI 탭에 들어간 뒤에는 하단 탭 아이콘을 찾을 수
/// 없어 이후 이동이 전부 실패한다. 처음 시도에서 04~08이 전부 같은 AI 화면으로
/// 찍힌 원인이 이것이었다.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 네트워크 응답을 기다린다. `pumpAndSettle`은 무한 애니메이션(스켈레톤·
  /// 광고 로딩)이 있으면 타임아웃 나므로 고정 시간으로 돌린다.
  Future<void> settle(WidgetTester tester, {int seconds = 5}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  // ⚠️ `convertFlutterSurfaceToImage()`는 **한 번만** 호출한다.
  // 매 촬영마다 부르면 표면이 첫 프레임에 고정돼 이후 화면 변화가 반영되지
  // 않는다 — 두 번째 시도에서 5장이 전부 같은 파일(동일 MD5)로 나온 원인.
  var surfaceReady = false;

  Future<void> shot(WidgetTester tester, String name) async {
    if (!surfaceReady) {
      await binding.convertFlutterSurfaceToImage();
      surfaceReady = true;
    }
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot(name);
  }

  /// 하단 탭 이동. 라벨은 로케일마다 다르므로 아이콘으로 찾는다.
  /// **실패하면 즉시 터뜨린다** — 조용히 같은 화면을 반복 캡처하는 것이
  /// 첫 시도의 실패 원인이었다.
  Future<void> tapTab(WidgetTester tester, IconData icon) async {
    final f = find.byIcon(icon);
    expect(f, findsWidgets, reason: '탭 아이콘 $icon 을 못 찾았다');
    await tester.tap(f.first);
    await settle(tester);
  }

  Future<void> scroll(WidgetTester tester, double dy, {int wait = 3}) async {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
    await settle(tester, seconds: wait);
  }

  testWidgets('앱스토어 스크린샷 8장', (tester) async {
    app.main();
    await settle(tester, seconds: 12);

    // 01 홈 — 거시지표 · 지수 카드 · 섹터 차트
    await shot(tester, '01_home');

    // 02 홈 하단 — 추천 종목 그리드(AI 점수)
    await scroll(tester, 900);
    await shot(tester, '02_home_picks');

    // 03 티커 상세 — 현재가 히어로 + 목표가 + AI 점수
    final ticker = find.textContaining(RegExp(r'^[A-Z]{2,5}$')).first;
    await tester.tap(ticker);
    await settle(tester, seconds: 9);
    await shot(tester, '03_ticker_hero');

    // 04 티커 상세 — 밸류에이션 · 애널리스트
    await scroll(tester, 1100);
    await shot(tester, '04_ticker_valuation');

    // 05 티커 상세 — 가격 차트
    await scroll(tester, 1900, wait: 4);
    await shot(tester, '05_ticker_chart');

    // 06 뉴스 — 종목별 뉴스 + 감성
    // `pageBack()`은 Cupertino 뒤로가기 버튼을 찾는다. 티커 상세는 Material
    // 라우트라 없으므로 시스템 pop을 직접 부른다.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await settle(tester, seconds: 3);
    await tapTab(tester, Icons.newspaper_outlined);
    await shot(tester, '06_news');

    // 07 홈 등락 탭 — 상승/하락 리스트
    await tapTab(tester, Icons.home_outlined);
    final upDown = find.byType(Tab);
    if (upDown.evaluate().length > 1) {
      await tester.tap(upDown.at(1));
      await settle(tester);
    }
    await shot(tester, '07_updown');

    // 08 AI 렌즈 — **마지막**. 여기 들어가면 탭바가 접혀 이동이 막힌다.
    await tapTab(tester, Icons.auto_awesome_outlined);
    await settle(tester, seconds: 4);
    await shot(tester, '08_ai');
  });
}
