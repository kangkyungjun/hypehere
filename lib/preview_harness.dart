// 디자인 프리뷰 하네스 (개발 전용, 배포 진입점 아님).
// 로그인·네트워크·탭 없이 티커상세 위젯을 목데이터로 렌더해 스크린샷 검증에 사용.
//   flutter run -t lib/preview_harness.dart -d <sim>
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'models/chart_data.dart';
import 'models/ticker_info.dart';
import 'screens/ticker_detail/widgets/ticker_header_widget.dart';
import 'screens/ticker_detail/widgets/ticker_summary_cards.dart';
import 'screens/ticker_detail/widgets/valuation_card.dart';
import 'screens/ticker_detail/widgets/ticker_price_chart.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    final data = <ChartDataPoint>[
      // 레퍼런스 차트는 감쇠 곡선이다. 직선 목데이터로는 스플라인 보간과
      // 헤일로 마커의 곡선감을 검증할 수 없어 완만한 파형을 넣는다.
      for (int i = 0; i < 30; i++)
        ChartDataPoint(
          date: DateTime(2026, 8, 1).add(Duration(days: i)),
          close: 140 +
              18 * (1 - 1 / (1 + i / 6)) +
              3.2 * math.sin(i / 2.6) +
              1.4 * math.cos(i / 1.3),
          score: 85,
          signal: 'strong_buy',
          targetPrice: 166.77,
        ),
    ];
    final chart = CompleteChartData(
      ticker: 'MRNA',
      data: data,
      analystConsensus: AnalystConsensus(
        mean: 95.67, high: 170, low: 25, count: 18, recommendation: 'hold',
      ),
    );
    final info = TickerInfo(
      ticker: 'MRNA', name: 'Moderna', nameKo: '모데나', category: 'Biotechnology',
    );
    final metrics = KeyMetrics(
      pe: null, forwardPe: -31.7, eps: -7.98,
      pb: 2.14, ps: 3.8, roe: -12.4, roa: -8.1, debtToEquity: 28.4,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      // 실제 앱과 동일 조건에서 봐야 의미가 있다 —
      // Pretendard + ColorScheme 정합 오버라이드를 그대로 건다.
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: MarketLensColors.light.groupedBackground,
        extensions: const [MarketLensColors.light],
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A56DB),
              brightness: Brightness.light,
              surface: MarketLensColors.light.cardBackground,
            ).copyWith(
              primary: MarketLensColors.light.accentBlue,
              onSurface: MarketLensColors.light.textPrimary,
              onSurfaceVariant: MarketLensColors.light.textSecondary,
              outline: MarketLensColors.light.textTertiary,
              outlineVariant: MarketLensColors.light.subtleBorder,
              error: MarketLensColors.light.dangerColor,
            ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PREVIEW: 티커상세 위젯'),
          backgroundColor: MarketLensColors.light.sectionBackground,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 레퍼런스 차트 언어 검증 대상 — 스크롤 없이 보이도록 맨 위.
                TickerPriceChart(
                  chartData: chart,
                  selectedPeriod: '1M',
                  periodDays: const {'1M': 30, '3M': 90, '1Y': 365},
                  onPeriodChanged: (_) {},
                ),
                const SizedBox(height: AppSpacing.xl),
                TickerHeaderWidget(
                  chartData: chart,
                  tickerInfo: info,
                  onScrollToAIInsight: () {},
                ),
                const SizedBox(height: AppSpacing.md),
                TickerSummaryCards(
                  chartData: chart,
                  tickerInfo: info,
                  onScrollToAIInsight: () {},
                ),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: ValuationCard(metrics: metrics),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
