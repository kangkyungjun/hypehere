import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/theme/app_spacing.dart';
import 'package:marketlens/widgets/common/bento_card.dart';
import 'package:marketlens/widgets/common/ml_key_value_row.dart';
import 'package:marketlens/widgets/common/section_header.dart';

/// 공용 프리미티브 갤러리 골든.
///
/// 프리미티브는 앱 전역에 파급되므로 한 번 깨지면 여러 화면이 동시에 무너진다.
/// 모든 변형(variant)을 한 페이지에 렌더해 라이트/다크 PNG로 고정해 두면,
/// 토큰을 만질 때마다 diff 두 장으로 회귀를 즉시 볼 수 있다.
///
/// 마스터 갱신:
///   flutter test --update-goldens test/ml_primitives_golden_test.dart
void main() {
  for (final (name, brightness, colors) in [
    ('light', Brightness.light, MarketLensColors.light),
    ('dark', Brightness.dark, MarketLensColors.dark),
  ]) {
    testWidgets('Ml primitives gallery — $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 720));

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: brightness,
            extensions: [colors],
            scaffoldBackgroundColor: colors.groupedBackground,
          ),
          home: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(title: 'KeyValue — row'),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: BentoCard(
                        child: Column(
                          children: const [
                            MlKeyValueRow(label: '평단가', value: r'$142.30'),
                            MlKeyValueRow(
                              label: '평가액',
                              value: r'$1,204.55',
                              emphasis: MlKvEmphasis.strong,
                            ),
                            MlKeyValueRow(
                              label: '평가손익',
                              value: '-8.42',
                              unit: '%',
                              emphasis: MlKvEmphasis.directional,
                              sub: '(-\$110.20)',
                            ),
                            MlKeyValueRow(
                              label: '목표가',
                              value: r'$212.00',
                              emphasis: MlKvEmphasis.blue,
                            ),
                            MlKeyValueRow(label: '배당수익률', value: ''),
                          ],
                        ),
                      ),
                    ),
                    const SectionHeader(
                      title: 'KeyValue — stack / dense',
                      subtitle: '3열 그리드 셀',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: BentoCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(
                              child: MlKeyValueRow(
                                label: '현재 PER',
                                value: '18.4',
                                layout: MlKvLayout.stack,
                                emphasis: MlKvEmphasis.strong,
                                dense: true,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: MlKeyValueRow(
                                label: '선행 PER',
                                value: '-31.7',
                                layout: MlKvLayout.stack,
                                emphasis: MlKvEmphasis.strong,
                                dense: true,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: MlKeyValueRow(
                                label: 'EPS',
                                value: r'$-7.98',
                                layout: MlKvLayout.stack,
                                emphasis: MlKvEmphasis.strong,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SectionHeader(
                      title: '라벨 고정폭',
                      subtitle: '값 시작 x 정렬',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: BentoCard(
                        child: Column(
                          children: const [
                            MlKeyValueRow(
                              label: '사고',
                              value: '완전무사고',
                              labelWidth: 64,
                            ),
                            MlKeyValueRow(
                              label: '상태',
                              value: '외판 2판',
                              labelWidth: 64,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/ml_primitives_$name.png'),
      );
    });
  }
}
