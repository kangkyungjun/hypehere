import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/widgets/common/ml_expandable_card.dart';

/// 확장 카드의 **동작** 계약을 고정한다.
///
/// 골든은 정지 화면만 잡는다. 확장은 상태 전이라 위젯 테스트로 눌러봐야
/// 검증된다 — 특히 개편 전 13벌이 제각각이던 지점들:
/// 토글 극성, 접힌 동안 detail 미생성, 접근성 expanded 플래그.
Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    extensions: const [MarketLensColors.light],
  ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('접힘이 기본 — detail은 생성조차 되지 않는다', (tester) async {
    var built = 0;
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          header: const Text('제목'),
          detail: (_) {
            built++;
            return const Text('상세');
          },
        ),
      ),
    );

    expect(find.text('제목'), findsOneWidget);
    expect(find.text('상세'), findsNothing);
    // 빌더로 받는 이유 — 접힌 동안 비용을 치르지 않는다.
    expect(built, 0);
  });

  testWidgets('탭하면 펼쳐지고 다시 탭하면 접힌다', (tester) async {
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          header: const Text('제목'),
          detail: (_) => const Text('상세'),
        ),
      ),
    );

    await tester.tap(find.text('제목'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsOneWidget);

    await tester.tap(find.text('제목'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsNothing);
  });

  testWidgets('initiallyExpanded: true — 극성이 뒤집히지 않는다', (tester) async {
    // 개편 전 key_news_card는 `_collapsed`(다른 곳은 전부 `_expanded`)라
    // 극성이 반대였고 chevron turns도 뒤집혀 있었다.
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          initiallyExpanded: true,
          header: const Text('제목'),
          detail: (_) => const Text('상세'),
        ),
      ),
    );
    expect(find.text('상세'), findsOneWidget);

    await tester.tap(find.text('제목'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsNothing);
  });

  testWidgets('headerOnly — 본문 탭은 토글하지 않는다', (tester) async {
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          initiallyExpanded: true,
          tapTarget: MlExpandTapTarget.headerOnly,
          header: const Text('제목'),
          detail: (_) => const Text('상세'),
        ),
      ),
    );

    await tester.tap(find.text('상세'));
    await tester.pumpAndSettle();
    // 본문에 링크·버튼이 있는 카드에서 오작동하지 않아야 한다.
    expect(find.text('상세'), findsOneWidget);
  });

  testWidgets('onExpansionChanged가 새 상태를 알린다', (tester) async {
    final events = <bool>[];
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          header: const Text('제목'),
          detail: (_) => const Text('상세'),
          onExpansionChanged: events.add,
        ),
      ),
    );

    await tester.tap(find.text('제목'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제목'));
    await tester.pumpAndSettle();

    expect(events, [true, false]);
  });

  testWidgets('접근성 — expanded 플래그가 스크린리더에 노출된다', (tester) async {
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          header: const Text('제목'),
          detail: (_) => const Text('상세'),
        ),
      ),
    );

    final handle = tester.ensureSemantics();

    // 접힘 상태
    expect(
      tester.getSemantics(find.byType(MlExpandableCard)),
      matchesSemantics(
        label: '제목',
        isButton: true,
        isFocusable: true,
        hasExpandedState: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    await tester.tap(find.text('제목'));
    await tester.pumpAndSettle();

    // 펼침 상태 — isExpanded가 켜져야 스크린리더가 상태 변화를 읽는다
    expect(
      tester.getSemantics(find.byType(MlExpandableCard)),
      matchesSemantics(
        // 펼치면 상세 텍스트가 같은 노드로 합쳐진다 — 스크린리더가 카드를
        // 하나의 버튼으로 읽고 그 안의 내용을 이어 읽는 정상 동작.
        label: '제목\n상세',
        isButton: true,
        isFocusable: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('card: false — 카드 표면 없이 동작만 제공한다', (tester) async {
    // 이미 카드 안에 들어가는 섹션이 이중 카드가 되지 않아야 한다.
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          card: false,
          header: const Text('제목'),
          detail: (_) => const Text('상세'),
        ),
      ),
    );

    await tester.tap(find.text('제목'));
    await tester.pumpAndSettle();
    expect(find.text('상세'), findsOneWidget);
  });

  testWidgets('showChevron: false + headerBuilder — 호출부가 어포던스를 갖는다', (
    tester,
  ) async {
    // 가운데 정렬 토글 링크처럼 트리거 모양이 이미 정해진 경우.
    // 상태·애니메이션·접근성은 프리미티브가 제공하되 chevron은 넘긴다.
    await tester.pumpWidget(
      _host(
        MlExpandableCard(
          card: false,
          showChevron: false,
          tapTarget: MlExpandTapTarget.headerOnly,
          headerBuilder: (_, expanded) => Text(expanded ? '접기' : '펼치기'),
          detail: (_) => const Text('상세'),
        ),
      ),
    );

    expect(find.text('펼치기'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);

    await tester.tap(find.text('펼치기'));
    await tester.pumpAndSettle();

    // 라벨이 상태를 따라간다
    expect(find.text('접기'), findsOneWidget);
    expect(find.text('상세'), findsOneWidget);
  });

  testWidgets('header와 headerBuilder를 동시에 주면 assert', (tester) async {
    expect(
      () => MlExpandableCard(
        header: const Text('제목'),
        headerBuilder: (_, __) => const Text('제목'),
        detail: (_) => const Text('상세'),
      ),
      throwsAssertionError,
    );
  });
}
