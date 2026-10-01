/// 캡쳐와 오버플로 검사가 **같은 화면**을 렌더하도록 조립을 한곳에 둔다.
///
/// 따로 두면 한쪽만 고쳐져서, 캡쳐는 멀쩡한데 검사는 옛 화면을 보는 일이 생긴다.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import 'package:marketlens/exceptions/api_error_codes.dart';
import 'package:marketlens/exceptions/api_exception.dart';
import 'package:marketlens/widgets/common/data_unavailable_view.dart';
import 'package:marketlens/widgets/news/mention_bubble_card.dart';
import 'package:marketlens/widgets/news/news_article_row.dart';
import 'package:marketlens/widgets/news/news_detail_sheet.dart';


/// 테스트 기본 폰트는 모든 글리프가 정사각형이라 **숫자 폭이 실제의 1.8배**로
/// 측정된다. 폭·오버플로를 보려면 앱이 번들하는 폰트를 그대로 써야 한다.
/// 관심종목·구독 프로바이더가 생성 시 SharedPreferences를 읽는다.
void mockPlatformChannels() {
  SharedPreferences.setMockInitialValues({});
}

Future<void> loadAppFont() async {
  final loader = FontLoader('Pretendard');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(Future.value(ByteData.view(
      File('assets/fonts/Pretendard-$w.otf').readAsBytesSync().buffer,
    )));
  }
  await loader.load();
}

/// 아이폰 16 Pro 논리 해상도.
const double screenW = 402;
const double screenH = 874;

/// 모든 화면 조립을 담는다. 테스트가 `ScreenHarness()`를 만들어 쓴다.
class ScreenHarness {
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

  late final indices = MarketIndicesData(date: '2026-09-30', indices: [
    idx('DIA', 'Dow Jones', 43535.06, -0.03),
    idx('QQQ', 'NASDAQ 100', 20716.43, -0.65),
    idx('SPY', 'S&P 500', 6769.35, -0.23),
  ]);

  late final signals = MacroSignalsData(date: '2026-09-30', signals: [
    MacroSignal(
      signalCode: 'overall_macro',
      value: 1,
      riskLevel: 'low',
      message: '거시경제 전반적으로 안정적. 정상 투자 유지.',
      date: '2026-09-30',
    ),
  ]);

  late final vix = MacroIndicator(
    indicatorCode: 'VIXCLS',
    indicatorName: 'VIX',
    value: 14.21,
    changePct: 0.0,
    high3m: 16.1,
    avg3m: 16.1,
  );
  late final tnx = MacroIndicator(
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

  late final recos = [
    it('PANW', '팔로알토 네트웍스', 71, 392.09, -1.23),
    it('ZS', '주식회사 지스케일러', 66, 199.39, 0.84),
    it('SNDK', '샌디스크', 68, 88.12, 2.10),
    it('BE', '블룸 에너지', 65, 41.55, -0.42),
  ];

  late final sectors = [
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
  late final bubbles = MentionBubbleData(
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

  late final articles = [
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

  late final watchScores = {
    'NVDA': score('NVDA', '엔비디아', 78, 184.22, 1.84),
    'AAPL': score('AAPL', '애플', 66, 271.40, -0.52),
    'GOOGL': score('GOOGL', '알파벳', 71, 254.11, 0.93),
    'TSLA': score('TSLA', '테슬라', 54, 412.05, -2.31),
  };
  static const watchEnrich = {
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

  late final holdings = [
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

  // 실패 상태 3종을 한 화면에 — 생김새가 같은 계열인지 눈으로 본다.
  Widget failureStates() => Column(
        children: [
          Expanded(
            child: DataUnavailableView.fromError(
              TickerNotFoundException(ticker: 'BE'),
              subject: 'BE',
              onReport: () {},
              onBack: () {},
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: DataUnavailableView.fromError(
              ApiException(ApiErrorCode.networkFailed),
              onRetry: () {},
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: DataUnavailableView.fromError(
              ApiException(ApiErrorCode.serverError),
              subject: 'GOOGL',
              onRetry: () {},
              onReport: () {},
            ),
          ),
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
          size: const Size(screenW, screenH),
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


  /// 이름 → 화면. 스윕 테스트가 전수 순회한다.
  Map<String, Widget Function()> get screens => {
        'home': homeToday,
        'news': newsTimeline,
        'sheet': detailSheet,
        'watchlist': watchlist,
        'portfolio': portfolio,
        'failure': failureStates,
      };
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
