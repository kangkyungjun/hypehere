@Tags(['capture'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/models/indices_data.dart';
import 'package:marketlens/models/macro_data.dart';
import 'package:marketlens/models/mention_bubble_data.dart';
import 'package:marketlens/models/news_data.dart';
import 'package:marketlens/models/treemap_data.dart';
import 'package:marketlens/theme/app_colors.dart';
import 'package:marketlens/theme/app_spacing.dart';
import 'package:marketlens/theme/app_typography.dart';
import 'package:marketlens/widgets/charts/macro_banner_widget.dart';
import 'package:marketlens/widgets/common/bento_card.dart';
import 'package:marketlens/widgets/dashboard/indices_bar_widget.dart';
import 'package:marketlens/widgets/dashboard/macro_strip_widget.dart';
import 'package:marketlens/widgets/dashboard/recommendation_grid.dart';
import 'package:marketlens/widgets/dashboard/sector_bar_chart_widget.dart';
import 'package:marketlens/widgets/news/mention_bubble_card.dart';
import 'package:marketlens/widgets/news/news_article_row.dart';

/// 디자인 검토용 스크린샷 생성기 (검증 테스트가 아니다).
///
/// 시뮬레이터가 Xcode 라이선스로 막혀 있어도 **아이폰 16 Pro 논리 해상도
/// (402×874 @3x)** 로 실제 위젯을 렌더해 PNG를 남긴다. 목데이터를 쓰므로
/// 로그인·네트워크가 필요 없고, 라이트/다크 × 1.0/1.3배를 한 번에 뽑는다.
///
/// ```
/// flutter test test/capture_screens_test.dart --tags capture
/// ```
/// 결과: `build/screens/*.png`
void main() {
  const w = 402.0, h = 874.0;
  final outDir = Directory('build/screens');

  setUpAll(() async {
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final loader = FontLoader('Pretendard');
    for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(Future.value(ByteData.view(
        File('assets/fonts/Pretendard-$f.otf').readAsBytesSync().buffer,
      )));
    }
    await loader.load();
  });

  // ── 목데이터 ────────────────────────────────────────────────────────────
  MarketIndexData idx(String code, String name, double close, double pct) =>
      MarketIndexData(
        code: code,
        name: name,
        close: close,
        prevClose: close * (1 - pct / 100),
        change: close * pct / 100,
        changePct: pct,
        // ⚠️ 무작위 톱니는 실제 지수와 다르게 보여 캡쳐를 왜곡한다.
        // 완만한 추세 + 작은 노이즈로 실제 차트 모양을 흉내낸다.
        chart: [
          for (var i = 0; i < 30; i++)
            IndexChartPoint(
              date: '2026-09-${(i % 30) + 1}',
              close: close *
                  (1 +
                      0.012 * math.sin(i / 7.0) +
                      0.004 * math.sin(i / 2.3) +
                      0.0015 * math.cos(i / 1.1)),
            ),
        ],
      );

  final indices = MarketIndicesData(date: '2026-09-30', indices: [
    idx('DIA', 'Dow Jones', 43535.06, -0.03),
    idx('QQQ', 'NASDAQ 100', 20716.43, -0.65),
    idx('SPY', 'S&P 500', 6769.35, -0.23),
  ]);

  final signals = MacroSignalsData(date: '2026-09-30', signals: [
    MacroSignal(
      signalCode: 'overall_macro',
      value: 1,
      riskLevel: 'low',
      message: '거시경제 전반적으로 안정적. 정상 투자 유지.',
      date: '2026-09-30',
    ),
  ]);

  final vix = MacroIndicator(
    indicatorCode: 'VIXCLS',
    indicatorName: 'VIX',
    value: 14.21,
    changePct: 0.0,
    high3m: 16.1,
    avg3m: 16.1,
  );
  final tnx = MacroIndicator(
    indicatorCode: 'DGS10',
    indicatorName: '10년물 국채금리',
    value: 5.18,
  );

  TreemapItem it(String t, String ko, double score, double close, double pct) =>
      TreemapItem(
        ticker: t,
        nameKo: ko,
        name: ko,
        score: score,
        close: close,
        changePct: pct,
        tradingValue: 1e9,
      );

  final recos = [
    it('PANW', '팔로알토 네트웍스', 71, 392.09, -1.23),
    it('ZS', '주식회사 지스케일러', 66, 199.39, 0.84),
    it('SNDK', '샌디스크', 68, 88.12, 2.10),
    it('BE', '블룸 에너지', 65, 41.55, -0.42),
  ];

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

  // ── 화면 조립 ───────────────────────────────────────────────────────────
  Widget homeToday() => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        // `dashboard_screen.dart:272-380`의 조립을 그대로 옮긴 것이다.
        // (광고·로딩 분기만 뺐다)
        children: [
          BentoCard(
            padding: EdgeInsets.zero,
            child: MacroBannerWidget(signals: signals),
          ),
          const SizedBox(height: AppDensity.cardGap),
          MacroStripWidget(vix: vix, treasury10y: tnx),
          const SizedBox(height: AppDensity.cardGap),
          IndicesBarWidget(data: indices),
          const SizedBox(height: AppDensity.cardGap),
          BentoCard(child: SectorBarChartWidget(sectors: sectors, onTap: () {})),
          Padding(
            padding: const EdgeInsets.only(top: AppDensity.sectionGap),
            child: RecommendationGrid(items: recos, onTickerTap: (_) {}),
          ),
        ],
      );

  // 캡쳐와 같은 분포: 큰 것 2개(혼합/약세) + 중간 + 작은 것들.
  final bubbles = MentionBubbleData(
    periodHours: 24,
    items: [
      TickerMention(ticker: 'META', mentionCount: 35, dominantSentiment: 'neutral'),
      TickerMention(ticker: 'DOW', mentionCount: 33, dominantSentiment: 'bearish'),
      TickerMention(ticker: 'AMD', mentionCount: 24, dominantSentiment: 'bullish'),
      TickerMention(ticker: 'DELL', mentionCount: 21, dominantSentiment: 'bullish'),
      TickerMention(ticker: 'HAS', mentionCount: 19, dominantSentiment: 'bullish'),
      TickerMention(ticker: 'C', mentionCount: 17, dominantSentiment: 'bullish'),
      TickerMention(ticker: 'JPM', mentionCount: 14, dominantSentiment: 'neutral'),
      TickerMention(ticker: 'MCD', mentionCount: 12, dominantSentiment: 'bullish'),
      TickerMention(ticker: 'LLY', mentionCount: 11, dominantSentiment: 'bullish'),
      TickerMention(ticker: 'CPB', mentionCount: 9, dominantSentiment: 'bullish'),
    ],
  );

  NewsItem news({
    required String ticker,
    String? nameKo,
    required String summary,
    required String grade,
    required String label,
    required String source,
    required String sector,
    required int minutesAgo,
    bool breaking = false,
  }) =>
      NewsItem(
        date: '2026-09-30',
        ticker: ticker,
        title: summary,
        source: source,
        publishedAt: DateTime.now().toUtc().subtract(Duration(minutes: minutesAgo)),
        aiSummary: summary,
        sentimentGrade: grade,
        sentimentLabel: label,
        tickerNameKo: nameKo,
        sector: sector,
        isBreaking: breaking,
      );

  final articles = [
    news(
      ticker: 'GRMN',
      nameKo: '가민',
      summary: '가민은 최근 애널리스트들로부터 \'중립 매수\'라는 합의 추천을 '
          '받았습니다. 이 추천은 회사의 주가에 긍정적인 영향을 미칠 것으로 보입니다.',
      grade: 'neutral',
      label: '중립',
      source: 'MarketBeat',
      sector: 'Consumer Discretionary',
      minutesAgo: 19,
    ),
    news(
      ticker: 'WMT',
      nameKo: '월마트',
      summary: '월마트는 인도에서 새로운 AI 쇼핑 테스트를 시작했습니다. '
          '이는 고객 경험을 개선하고 판매를 늘리는 데 도움이 될 수 있습니다.',
      grade: 'bullish',
      label: '강세',
      source: 'simplywall.st',
      sector: 'Consumer Staples',
      minutesAgo: 21,
      breaking: true,
    ),
    news(
      ticker: 'META',
      nameKo: '메타 플랫폼스',
      summary: '메타가 데이터센터 투자를 확대한다고 발표하면서 단기 마진 압박 '
          '우려가 제기됐습니다.',
      grade: 'bearish',
      label: '약세',
      source: 'Reuters',
      sector: 'Communication Services',
      minutesAgo: 44,
    ),
  ];

  Widget newsTimeline() => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          MentionBubbleCard(data: bubbles),
          Padding(
            padding: const EdgeInsets.only(
              top: AppDensity.sectionGap,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              '오늘 · 9/30 수',
              style: AppTypography.label.copyWith(
                color: MarketLensColors.light.textTertiary,
              ),
            ),
          ),
          for (final a in articles) NewsArticleRow(item: a, onTap: () {}),
        ],
      );

  Widget app(Widget body, {required bool dark, required double scale}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: dark
            ? MarketLensColors.dark.groupedBackground
            : MarketLensColors.light.groupedBackground,
        extensions: [dark ? MarketLensColors.dark : MarketLensColors.light],
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(w, h),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: SafeArea(child: body)),
      ),
    );
  }

  Future<void> shoot(WidgetTester tester, String name, Widget child) async {
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: child));
    // ⚠️ `pumpAndSettle`을 쓰지 않는다. 첫 인자는 **타임아웃이 아니라 펌프
    // 간격**이고, 기본 타임아웃은 가짜시계 10분이다. 화면에 계속 프레임을
    // 스케줄하는 위젯이 하나라도 있으면 변이마다 10분을 태운다(실제로 그랬다).
    // 스크린샷은 레이아웃만 잡히면 되므로 두 번 펌프하면 충분하다.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    // ⚠️ `toImage`/`toByteData`는 엔진 콜백으로 완료되므로 **실제 비동기**가
    // 필요하다. `testWidgets`의 가짜 비동기 존에서 그냥 await하면 PNG는
    // 쓰이지만 그 뒤로 Future가 영영 안 풀려 테스트가 10분 타임아웃까지
    // 매달린다(CPU 0%로 순수 대기). `runAsync`가 진짜 이벤트 루프를 준다.
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      png = data!.buffer.asUint8List();
      image.dispose(); // 남겨두면 엔진이 이미지를 붙들고 있다.
    });

    File('${outDir.path}/$name.png').writeAsBytesSync(png);
  }

  final variants = [
    ('light-1.0x', false, 1.0),
    ('light-1.3x', false, 1.3),
    ('dark-1.0x', true, 1.0),
  ];

  for (final v in variants) {
    testWidgets('capture news ${v.$1}', (tester) async {
      tester.view.physicalSize = const Size(w * 3, h * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await shoot(
        tester,
        'news-${v.$1}',
        app(newsTimeline(), dark: v.$2, scale: v.$3),
      );
    });

    testWidgets('capture home ${v.$1}', (tester) async {
      tester.view.physicalSize = const Size(w * 3, h * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await shoot(
        tester,
        'home-${v.$1}',
        app(homeToday(), dark: v.$2, scale: v.$3),
      );
    });
  }
}
