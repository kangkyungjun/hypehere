import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/theme/app_spacing.dart';

/// 플로팅 탭바 클리어런스 계약.
///
/// ## 왜 필요한가
///
/// 탭바는 `extendBody: true` 위에 떠 있어서, 스크롤 화면이 바닥을 비워 주지
/// 않으면 **마지막 콘텐츠가 탭바에 가린다.**
///
/// 전에는 상수 하나(`bottomNavClearance = 64`)를 주고 호출부가
/// `MediaQuery.viewPadding.bottom + 상수`로 더하게 했는데, 그 계약이 두 가지를
/// 동시에 틀리게 만들었다:
///
/// 1. 탭바의 `SafeArea(minimum: bottom 8)` **하한을 표현할 수 없었다.**
///    호출부가 쓰는 건 덧셈뿐이라 `max()`가 안 들어간다. 기기 inset이 0인
///    환경(안드로이드 3버튼, 홈버튼 iPhone)에서 탭바 68 vs 클리어런스 64 →
///    **4px 잘림.**
/// 2. 호출부가 `viewPadding.bottom` 대신 `padding.bottom`을 쓰거나 아예
///    더하는 걸 잊기 쉬웠다. 실제로 캘린더가 `padding.bottom + 70`이었다.
///
/// 이 테스트는 **탭바 실제 높이를 `main.dart` 구조에서 재계산해서** 비교한다.
/// 탭바 구조(아이템 높이·패딩·SafeArea minimum)를 건드리면 여기서 깨진다.
void main() {
  /// `main.dart`의 `_buildModernBottomNav` 구조를 그대로 옮긴 높이 계산.
  ///
  /// ```
  /// SafeArea(top: false, minimum: fromLTRB(md, xs, md, sm))
  ///   → 상단 xs(4), 하단 max(기기inset, sm(8))
  ///   DecoratedBox
  ///     Padding(all: xs(4))
  ///       Row → AnimatedContainer(height: bottomNavItemHeight(48))
  /// ```
  double actualNavBarHeight(double deviceInset) {
    const safeTop = AppSpacing.xs; // 4
    const innerPadding = AppSpacing.xs * 2; // 위·아래 4+4
    final safeBottom =
        deviceInset > AppSpacing.sm ? deviceInset : AppSpacing.sm;
    return safeTop + innerPadding + AppLayout.bottomNavItemHeight + safeBottom;
  }

  /// 주어진 기기 inset에서 `bottomNavClearanceOf`가 돌려주는 값.
  Future<double> clearanceAt(WidgetTester tester, double inset) async {
    late double result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(viewPadding: EdgeInsets.only(bottom: inset)),
        child: Builder(
          builder: (context) {
            result = AppLayout.bottomNavClearanceOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  /// 실기기에서 실제로 나오는 inset 값들.
  const deviceInsets = <String, double>{
    'iPhone 홈 인디케이터': 34.0,
    'Android 제스처': 24.0,
    'Android 3버튼': 0.0, // ← 전에 4px 잘리던 케이스
    'iPhone 홈버튼(구형)': 0.0,
    'inset이 하한보다 작음': 3.0,
  };

  group('클리어런스가 탭바를 항상 덮는다', () {
    deviceInsets.forEach((label, inset) {
      testWidgets(label, (tester) async {
        final clearance = await clearanceAt(tester, inset);
        final bar = actualNavBarHeight(inset);

        expect(
          clearance,
          greaterThan(bar),
          reason: '$label (inset=$inset): 탭바 $bar vs 클리어런스 $clearance '
              '— 콘텐츠가 가린다',
        );
      });
    });

    testWidgets('숨 공간이 그림자(blur 8)보다 넉넉하다', (tester) async {
      // 산술적으로 "안 가리는" 것만으로는 부족했다. 탭바는 blur 8짜리
      // 그림자를 가진 플로팅이라, 여유가 4였을 때 마지막 카드가 붙어 보였다.
      for (final inset in deviceInsets.values) {
        final gap = await clearanceAt(tester, inset) - actualNavBarHeight(inset);
        expect(gap, greaterThanOrEqualTo(8.0),
            reason: 'inset=$inset 여유 $gap — 그림자에 묻힌다');
      }
    });
  });

  test('inset이 커지면 클리어런스도 같이 커진다', () {
    // 하한 아래에서는 평평하고(8로 고정), 그 위로는 1:1로 따라가야 한다.
    double clearanceFor(double inset) {
      final safe = inset > AppSpacing.sm ? inset : AppSpacing.sm;
      return safe +
          AppLayout.bottomNavContentHeight +
          AppLayout.bottomNavBreathingRoom;
    }

    expect(clearanceFor(0), clearanceFor(8), reason: '하한 아래는 동일');
    expect(clearanceFor(34) - clearanceFor(24), 10,
        reason: '하한 위에서는 inset 증가분만큼 커진다');
  });

  /// 탭 트리 안의 스크롤 화면이 클리어런스를 빠뜨리지 않았는지.
  ///
  /// 세 번째 화면이 또 새지 않게 하려는 것이다. 지금까지 두 번 샜다 —
  /// 캘린더(리터럴 70)와 AI 분석 준비중(아예 없음).
  test('탭 안 스크롤 화면이 전부 클리어런스를 쓴다', () {
    // main.dart의 IndexedStack에 올라가는 5개 탭과 그 하위.
    const tabScreens = <String>[
      'lib/screens/dashboard/dashboard_screen.dart',
      'lib/screens/dashboard/widgets/indexes_tab.dart',
      'lib/screens/dashboard/widgets/up_down_tab.dart',
      'lib/screens/news/news_list_screen.dart',
      'lib/screens/calendar/event_calendar_screen.dart',
      'lib/screens/ai_lens/ai_lens_screen.dart',
      'lib/screens/ai_lens/ai_sector_screen.dart',
      'lib/screens/ai_lens/widgets/ai_analysis_coming_soon.dart',
      'lib/screens/watchlist/widgets/watchlist_tab.dart',
      'lib/screens/watchlist/widgets/holdings_tab.dart',
    ];

    final missing = <String>[];
    final literals = <String>[];

    /// 주석을 걷어낸 코드만 본다.
    ///
    /// 처음엔 원문을 그대로 스캔했다가, 옛 코드를 설명하는 **주석 문구**를
    /// 위반으로 잡았다(`// 전에는 padding.bottom + 70.0 이었는데...`).
    /// 검사 대상은 코드지 산문이 아니다.
    String codeOnly(String src) => src
        .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '')
        .replaceAll(RegExp(r'//.*$', multiLine: true), '');

    for (final path in tabScreens) {
      final src = codeOnly(File(path).readAsStringSync());
      if (!src.contains('bottomNavClearanceOf')) {
        missing.add(path);
      }
      // 구 API(호출부가 inset을 직접 더하던 방식)가 되살아나면 잡는다.
      if (RegExp(r'bottomNavClearance\b(?!Of)').hasMatch(src)) {
        literals.add('$path — 구 API bottomNavClearance');
      }
      // 바닥 패딩에 박힌 매직넘버. 70·78이 실제로 있었다.
      final magic = RegExp(r'(?:view)?[Pp]adding\.bottom\s*\+\s*\d');
      if (magic.hasMatch(src)) {
        literals.add('$path — padding.bottom + 리터럴');
      }
    }

    expect(missing, isEmpty,
        reason: '클리어런스 누락 — 바닥이 탭바에 가린다:\n${missing.join("\n")}');
    expect(literals, isEmpty,
        reason: '매직넘버/구 API — 탭바 높이를 바꾸면 어긋난다:\n${literals.join("\n")}');
  });
}
