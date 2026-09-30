@Tags(['capture'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketlens/l10n/app_localizations.dart';
import 'package:marketlens/models/indices_data.dart';
import 'package:marketlens/models/macro_data.dart';
import 'package:marketlens/models/mention_bubble_data.dart';
import 'package:marketlens/models/portfolio_data.dart';
import 'package:marketlens/models/ticker_score.dart';
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
import 'package:provider/provider.dart';

import 'package:marketlens/providers/auth_provider.dart';
import 'package:marketlens/providers/portfolio_provider.dart';
import 'package:marketlens/providers/subscription_provider.dart';
import 'package:marketlens/providers/watchlist_provider.dart';
import 'package:marketlens/screens/watchlist/widgets/holding_list_item.dart';
import 'package:marketlens/screens/watchlist/widgets/portfolio_summary_card.dart';
import 'package:marketlens/screens/watchlist/widgets/watchlist_tab.dart';
import 'package:marketlens/widgets/news/mention_bubble_card.dart';
import 'package:marketlens/widgets/news/news_article_row.dart';
import 'package:marketlens/widgets/news/news_detail_sheet.dart';

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
    // 구독·관심종목 프로바이더가 생성 시 SharedPreferences를 읽는다.
    SharedPreferences.setMockInitialValues({});
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
    required String title,
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
        title: title,
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
      title: 'Garmin Receives Consensus "Moderate Buy" Rating from Analysts',
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
      title: 'Walmart Launches New AI Shopping Pilot in India',
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
      title: 'Meta Expands Data Center Spending, Raising Margin Concerns',
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

  // 기사 상세 시트 — 리스트 행을 탭하면 열린다.
  Widget detailSheet() => Align(
        alignment: Alignment.bottomCenter,
        child: NewsDetailSheet(
          item: articles[0],
          onOpenOriginal: () {},
          onOpenTicker: () {},
        ),
      );

  // ── 관심종목 ─────────────────────────────────────────────────────────
  TickerScore score(String t, String ko, double sc, double close, double pct) =>
      TickerScore(
        ticker: t,
        score: sc,
        signal: sc >= 70 ? 'BUY' : 'HOLD',
        nameKo: ko,
        name: ko,
        close: close,
        changePct: pct,
      );

  final watchScores = {
    'NVDA': score('NVDA', '엔비디아', 78, 184.22, 1.84),
    'AAPL': score('AAPL', '애플', 66, 271.40, -0.52),
    'GOOGL': score('GOOGL', '알파벳', 71, 254.11, 0.93),
    'TSLA': score('TSLA', '테슬라', 54, 412.05, -2.31),
  };
  const watchEnrich = {
    'NVDA': WatchlistEnrichment(target: 210.0, price1m: 172.3, price3m: 158.9),
    'AAPL': WatchlistEnrichment(target: 290.0, price1m: 265.1, price3m: 240.7),
    'GOOGL': WatchlistEnrichment(target: 275.0, price1m: 241.8, price3m: 219.4),
    'TSLA': WatchlistEnrichment(target: 380.0, price1m: 431.2, price3m: 398.6),
  };

  Widget watchlist() => WatchlistTab(
        tickerScores: watchScores,
        enrichment: watchEnrich,
        isLoading: false,
        onTickerTap: (_) {},
        onAddHolding: (_, __) {},
        onRefresh: () async {},
        onRetry: () {},
      );

  // ── 보유종목 ─────────────────────────────────────────────────────────
  PortfolioHolding hold(String t, String ko, double shares, double avg,
          double cur, double pct, double sc, String sig) =>
      PortfolioHolding(
        ticker: t,
        shares: shares,
        avgPrice: avg,
        name: ko,
        nameKo: ko,
        currentPrice: cur,
        changePct: pct,
        score: sc,
        signal: sig,
      );

  final holdings = [
    hold('NVDA', '엔비디아', 12, 142.10, 184.22, 1.84, 78, 'BUY'),
    hold('AAPL', '애플', 30, 254.80, 271.40, -0.52, 66, 'HOLD'),
    hold('TSLA', '테슬라', 5, 448.90, 412.05, -2.31, 54, 'SELL'),
  ];

  Widget portfolio() => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          PortfolioSummaryCard(portfolio: _MockPortfolio(holdings)),
          const SizedBox(height: AppDensity.sectionGap),
          for (final h in holdings)
            HoldingListItem(holding: h, onTap: () {}, onDelete: () {}),
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
        // main.dart가 `ColorScheme`을 우리 팔레트로 오버라이드한다. 이걸
        // 빼면 버튼이 시드 파생 보라로 나와 캡쳐가 실제와 달라진다.
        colorScheme: ColorScheme.fromSeed(
          seedColor: (dark ? MarketLensColors.dark : MarketLensColors.light)
              .accentBlue,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: (dark ? MarketLensColors.dark : MarketLensColors.light)
              .accentBlue,
          onPrimary: (dark ? MarketLensColors.dark : MarketLensColors.light)
              .onPrimary,
        ),
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
        // 관심종목 탭은 Auth·Portfolio·Subscription을 `context.watch`로 읽는다.
        // 캡쳐 하네스에도 얹어야 실제 화면과 같은 경로로 렌더된다.
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: _MockAuth()),
            ChangeNotifierProvider<PortfolioProvider>.value(
              value: _MockPortfolio(holdings),
            ),
            ChangeNotifierProvider<SubscriptionProvider>.value(
              value: _MockSubscription(),
            ),
            ChangeNotifierProvider<WatchlistProvider>.value(
              value: _MockWatchlist(watchScores.keys.toList()),
            ),
          ],
          child: Scaffold(body: SafeArea(child: body)),
        ),
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
    testWidgets('capture watchlist ${v.$1}', (tester) async {
      tester.view.physicalSize = const Size(w * 3, h * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await shoot(
        tester,
        'watchlist-${v.$1}',
        app(watchlist(), dark: v.$2, scale: v.$3),
      );
    });

    testWidgets('capture portfolio ${v.$1}', (tester) async {
      tester.view.physicalSize = const Size(w * 3, h * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await shoot(
        tester,
        'portfolio-${v.$1}',
        app(portfolio(), dark: v.$2, scale: v.$3),
      );
    });

    testWidgets('capture sheet ${v.$1}', (tester) async {
      tester.view.physicalSize = const Size(w * 3, h * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await shoot(
        tester,
        'sheet-${v.$1}',
        app(detailSheet(), dark: v.$2, scale: v.$3),
      );
    });

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

/// `PortfolioSummaryCard`가 데이터 모델이 아니라 **프로바이더**를 받는다.
/// 합계는 전부 private `_holdings`에서 계산되므로 게터만 덮어쓴다.
class _MockPortfolio extends PortfolioProvider {
  _MockPortfolio(this._items);

  final List<PortfolioHolding> _items;

  @override
  List<PortfolioHolding> get holdings => _items;

  @override
  double get totalValue =>
      _items.fold(0, (sum, h) => sum + h.currentValue);

  @override
  double get totalCost => _items.fold(0, (sum, h) => sum + h.costBasis);

  @override
  double get totalPnl => totalValue - totalCost;

  @override
  double get totalPnlPct => totalCost > 0 ? (totalPnl / totalCost) * 100 : 0;

  @override
  DateTime? get lastRefreshedAt => DateTime(2026, 10, 1, 9, 30);
}

/// 로그인 상태만 필요하다 — 비로그인이면 관심종목이 안내 배너로 바뀐다.
class _MockAuth extends AuthProvider {
  @override
  bool get isLoggedIn => true;
}

class _MockWatchlist extends WatchlistProvider {
  _MockWatchlist(this._tickers);

  final List<String> _tickers;

  @override
  List<String> get watchlist => _tickers;
}

class _MockSubscription extends SubscriptionProvider {
  @override
  bool get isGoldActive => false;
}
