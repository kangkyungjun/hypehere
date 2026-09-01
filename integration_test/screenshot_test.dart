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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 네트워크 응답을 기다린다. `pumpAndSettle`은 무한 애니메이션(스켈레톤·
  /// 광고 로딩)이 있으면 타임아웃 나므로 고정 시간으로 돌린다.
  Future<void> settle(WidgetTester tester, {int seconds = 5}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// 화면이 준비됐음을 로그로 알리고 잠시 멈춘다.
  ///
  /// ## 왜 `binding.takeScreenshot()`을 안 쓰나
  /// iOS integration_test의 `takeScreenshot`은 **매번 같은 이미지**를 돌려준다
  /// (4번 시도해 8장이 전부 동일 MD5). `convertFlutterSurfaceToImage()`는
  /// 안드로이드 전용이라 해법도 아니다.
  ///
  /// 그래서 캡처는 외부 `xcrun simctl io screenshot`에 맡기고, 이 테스트는
  /// **화면을 그 상태로 붙잡아 주는 역할**만 한다. `tool/capture_screens.sh`가
  /// 이 마커를 보고 찍는다.
  Future<void> shot(WidgetTester tester, String name) async {
    debugPrint('SHOT_READY:$name');
    await settle(tester, seconds: 4); // 외부 캡처가 끝날 시간
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

  /// 심사용 데모 계정으로 로그인한다.
  ///
  /// 관심종목·보유종목은 비로그인 시 "로그인하여 포트폴리오를 관리하세요"
  /// 안내만 나온다. 계정은 `fastlane/metadata/review_information/`의
  /// Apple 심사용 데모 계정을 그대로 쓴다.
  Future<bool> login(WidgetTester tester) async {
    final loginBtn = find.textContaining(RegExp(r'로그인|Log ?in|Sign ?in'));
    if (loginBtn.evaluate().isEmpty) return false;
    await tester.tap(loginBtn.first, warnIfMissed: false);
    await settle(tester, seconds: 4);

    final fields = find.byType(TextFormField);
    if (fields.evaluate().length < 2) return false;
    await tester.enterText(fields.at(0), 'test_appstore@apple.com');
    await tester.enterText(fields.at(1), '1234qwer!Q');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, seconds: 2);

    final submit = find.widgetWithText(ElevatedButton, '로그인');
    if (submit.evaluate().isNotEmpty) {
      await tester.tap(submit.first, warnIfMissed: false);
    }
    await settle(tester, seconds: 9);
    return true;
  }

  testWidgets('앱스토어 스크린샷 8장', (tester) async {
    app.main();
    await settle(tester, seconds: 14);

    // 01 홈 — 거시지표 · 지수 카드 · 섹터 차트
    await shot(tester, '01_home');

    // 02 홈 하단 — 추천 종목 그리드(AI 점수)
    await scroll(tester, 900);
    await shot(tester, '02_home_picks');

    // 03 티커 상세 — 현재가 히어로 + 목표가 + AI 점수
    await tester.tap(find.textContaining(RegExp(r'^[A-Z]{2,5}$')).first);
    await settle(tester, seconds: 9);
    await shot(tester, '03_ticker_hero');

    // 04 티커 상세 — 밸류에이션 · 애널리스트
    await scroll(tester, 1100);
    await shot(tester, '04_ticker_valuation');

    // 05 티커 상세 — 가격 차트
    await scroll(tester, 1900, wait: 4);
    await shot(tester, '05_ticker_chart');

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester, seconds: 3);

    // 06 뉴스 — ⚠️ 뉴스 탭의 **첫 화면은 캘린더**다(내부 탭: 캘린더 | 뉴스).
    // 두 번째 내부 탭으로 이동해야 실제 뉴스가 나온다.
    await tapTab(tester, Icons.newspaper_outlined);
    final innerTabs = find.byType(Tab);
    if (innerTabs.evaluate().length >= 2) {
      await tester.tap(innerTabs.at(1), warnIfMissed: false);
      await settle(tester, seconds: 4);
    }
    await shot(tester, '06_news');

    // 07 홈 등락 탭 — 시가총액/거래대금 상위
    await tapTab(tester, Icons.home_outlined);
    final homeTabs = find.byType(Tab);
    if (homeTabs.evaluate().length > 1) {
      await tester.tap(homeTabs.at(1), warnIfMissed: false);
      await settle(tester);
    }
    await shot(tester, '07_updown');

    // 08 관심종목 — 로그인이 되면 실제 목록, 안 되면 건너뛴다.
    await tapTab(tester, Icons.star_border_rounded);
    await login(tester);
    await settle(tester, seconds: 4);
    await shot(tester, '08_watchlist');
  });
}
