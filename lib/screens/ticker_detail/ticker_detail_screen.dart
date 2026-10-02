import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../widgets/common/data_unavailable_view.dart';
import '../../models/chart_data.dart';
import '../../models/ticker_change.dart';
import '../../models/ticker_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/charts/rsi_chart_widget.dart';
import '../../widgets/charts/company_profile_card.dart';
import '../../widgets/charts/events_calendar_widget.dart';
import '../../widgets/charts/ticker_news_card.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/ads/interstitial_ad_helper.dart';
import '../../config/feature_flags.dart';
import '../../widgets/common/gold_upgrade_sheet.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../watchlist/widgets/add_holding_sheet.dart';
import '../watchlist/widgets/instant_advice_sheet.dart';
import 'widgets/ticker_header_widget.dart';
import 'widgets/ticker_summary_cards.dart';
import 'widgets/ticker_price_chart.dart';
import 'widgets/ticker_volume_chart.dart';
import 'widgets/ticker_score_section.dart';
import 'widgets/valuation_card.dart';
import 'widgets/ticker_insight_section.dart';
import 'widgets/ticker_analyst_section.dart';
import 'widgets/ticker_community_section.dart';

/// Ticker Detail Screen - MarketLens 핵심 화면
///
/// ⚠️ HypeHere와 완전히 다른 UX:
/// - 순수 데이터 분석 도구
/// - 소셜 기능 없음 (좋아요/댓글/공유)
/// - 차트 중심 구조
class TickerDetailScreen extends StatefulWidget {
  final String ticker;

  /// Optional: scroll to a specific section on load ('news', etc.)
  final String? initialSection;

  const TickerDetailScreen({
    super.key,
    required this.ticker,
    this.initialSection,
  });

  @override
  State<TickerDetailScreen> createState() => _TickerDetailScreenState();
}

class _TickerDetailScreenState extends State<TickerDetailScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  CompleteChartData? _chartData;
  TickerInfo? _tickerInfo;

  /// 티커 변경 해소 결과. **차트가 비었을 때만** 채운다.
  ///
  /// 정상 경로에서는 받지 않는다 — 변경 맵은 데이터가 없을 때만 쓸모가
  /// 있고, 매 상세 화면마다 요청을 하나 더 붙일 이유가 없다.
  TickerResolution? _resolution;
  bool _isLoading = true;
  /// 원본 예외를 들고 있는다. 문자열로 바꿔 버리면 **네트워크 끊김인지
  /// 종목 데이터 부재인지 구분할 수 없어** 모두 같은 빨간 화면이 된다.
  Object? _error;

  // AI 의견 섹션 스크롤 타겟
  final GlobalKey _aiInsightKey = GlobalKey();

  // 뉴스 섹션 스크롤 타겟
  final GlobalKey _newsKey = GlobalKey();

  // 커뮤니티 섹션 키 (새로고침 용)
  final GlobalKey<TickerCommunitySectionState> _communityKey = GlobalKey();

  // 기간 선택
  String _selectedPeriod = '3M';
  final Map<String, int> _periodDays = {
    '1M': 30,
    '3M': 90,
    '6M': 180,
    '1Y': 365,
  };

  @override
  void initState() {
    super.initState();
    InterstitialAdHelper.instance.onTickerDetailViewed();
    _loadChartData();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  /// 서버 엔드포인트가 아직 없으면 **버튼 자체를 그리지 않는다.**
  /// 눌러도 아무 데도 안 가는 버튼은 지금의 어설픈 화면보다 나쁘다.
  VoidCallback? _reportDataIssue(BuildContext context) {
    if (!AnalyticsApiClient.dataIssueReportEnabled) return null;
    return () async {
      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);
      await _apiClient.reportDataIssue(
        subject: widget.ticker,
        kind: _error == null
            ? 'empty'
            : DataUnavailableView.kindOf(_error!).name,
        detail: _error?.toString(),
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.unavailableReportSent)),
      );
    };
  }

  /// 새 티커 화면으로 **교체** 이동.
  ///
  /// push가 아니라 pushReplacement다. 뒤로 가기를 눌렀을 때 방금 "이름이
  /// 바뀌었습니다"라고 알려준 화면으로 돌아가는 건 막다른 길이다.
  void _goToSuccessor(String newTicker) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TickerDetailScreen(ticker: newTicker),
      ),
    );
  }

  /// 길게 눌렀을 때 보여줄 개발자용 상세. 데이터가 언제까지 있었는지.
  String? _freshnessDetail() {
    final f = _chartData?.freshness;
    if (f == null) return null;
    final d = f.asOf.toIso8601String().split('T').first;
    final m = f.marketAsOf.toIso8601String().split('T').first;
    return 'as_of $d / market $m / ${f.tradingDaysBehind} trading days behind';
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _communityKey.currentState?.refresh();

    try {
      final days = _periodDays[_selectedPeriod] ?? 90;
      final toDate = DateTime.now();
      final fromDate = toDate.subtract(Duration(days: days));

      // 차트와 기업정보를 **독립적으로** 받는다.
      //
      // 개편 전에는 `Future.wait([chart, info])`였는데, `Future.wait`은
      // **하나라도 실패하면 전체를 버린다.** 그래서 기업정보가 404인 종목
      // (트리맵에는 있는데 정보 테이블에는 없는 BE 같은 케이스)은 차트가
      // 멀쩡해도 화면 전체가 에러로 떨어졌다.
      //
      // `_tickerInfo`는 이 화면의 모든 소비처에서 **이미 nullable**이다
      // (`:267` 표시명, `:469`·`:485` 섹션 인자). 즉 화면은 기업정보 없이도
      // 성립하도록 만들어져 있었는데 로딩이 그걸 막고 있었다.
      //
      // 차트는 화면의 뼈대라 실패하면 진짜 에러다. 기업정보는 보조 데이터라
      // 실패를 삼키고 null로 둔다 — 사용자는 실패를 느끼지 못한다.
      final chartFuture = _apiClient.getChartData(
        widget.ticker,
        fromDate: fromDate,
        toDate: toDate,
      );
      final infoFuture = _apiClient
          .getTickerInfo(widget.ticker)
          .then<TickerInfo?>((v) => v)
          .catchError((Object e) {
        debugPrint('[TICKER_INFO] ${widget.ticker} 실패 — 보조 데이터라 무시: $e');
        return null;
      });

      final chart = await chartFuture;
      final info = await infoFuture;

      // 차트가 비었다 — 개명·상장폐지일 수 있다. 그때만 변경 맵을 받는다.
      //
      // 이 분기가 전에는 "아직 데이터를 준비 중입니다"였다. BK를 들고 있던
      // 사용자에게 **틀린 설명**이다 — 준비 중이 아니라 BNY로 이름이 바뀐
      // 것이고, 데이터는 이미 다 있다.
      TickerResolution? resolution;
      if (chart.data.isEmpty) {
        final changes = await _apiClient.fetchTickerChanges();
        final r = changes.resolve(widget.ticker);
        if (r.shouldNotify) resolution = r;
      }

      if (!mounted) return;
      setState(() {
        _chartData = chart;
        _tickerInfo = info;
        _resolution = resolution;
        _isLoading = false;
      });

      // Auto-scroll to news section if requested
      if (widget.initialSection == 'news') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _newsKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: AppDuration.slow,
              curve: AppDuration.emphasized,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    if (period == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = period;
    });
    _reloadForPeriod();
  }

  /// 기간 변경 전용: _isLoading 건드리지 않고 차트 데이터만 교체
  Future<void> _reloadForPeriod() async {
    final days = _periodDays[_selectedPeriod] ?? 90;
    final toDate = DateTime.now();
    final fromDate = toDate.subtract(Duration(days: days));

    try {
      final newChartData = await _apiClient.getChartData(
        widget.ticker,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (mounted) {
        setState(() {
          _chartData = newChartData;
        });
      }
    } catch (_) {
      // 실패 시 기존 데이터 유지 — 사용자 경험 보호
    }
  }

  /// AI 의견 섹션으로 스크롤
  void _scrollToAIInsight() {
    final ctx = _aiInsightKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: AppDuration.slower,
        curve: AppDuration.emphasized,
      );
    }
  }

  /// 보유종목에 추가 (종목 상세에서 직접)
  Future<void> _onAddToPortfolio(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context);

    // Login check
    if (!auth.isLoggedIn) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => const SignupPromptDialog(),
      );
      if (result == null || !context.mounted) return;
      if (result == 'login') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else if (result == 'signup') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      }
      return;
    }

    final portfolio = context.read<PortfolioProvider>();
    final sub = context.read<SubscriptionProvider>();
    final ticker = widget.ticker;

    // Free user limit check (new ticker only)
    // Hybrid check: server role OR client-side RevenueCat status (webhook 지연 대비)
    // [GOLD_PURCHASE_FLAG] 골드 구매 비활성화 시 Holdings 제한 전체 스킵.
    // 복원: kGoldPurchaseEnabled = true → 3개 제한 + 업그레이드 다이얼로그 자동 복원.
    final isNewTicker = !portfolio.isInHoldings(ticker);
    if (FeatureFlags.kGoldPurchaseEnabled && isNewTicker && !auth.isGoldOrAbove && !sub.isGoldActive && portfolio.holdings.length >= 3) {
      if (!context.mounted) return;
      final upgradeResult = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: context.mlColors.accentBlue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.holdingsLimitTitle)),
            ],
          ),
          content: Text(l10n.holdingsLimitMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, 'upgrade'),
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: Text(l10n.upgradeToGold),
              style: FilledButton.styleFrom(
                backgroundColor: context.mlColors.accentBlue,
                foregroundColor: context.mlColors.onPrimary,
              ),
            ),
          ],
        ),
      );
      if (upgradeResult == 'upgrade' && context.mounted) {
        GoldUpgradeSheet.show(context, source: 'holdings_limit');
      }
      return;
    }

    // Display name from loaded ticker info
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = _tickerInfo != null
        ? (isKo && _tickerInfo!.nameKo != null
              ? _tickerInfo!.nameKo!
              : _tickerInfo!.name ?? ticker)
        : ticker;

    final result = await AddHoldingSheet.show(
      context,
      ticker: ticker,
      name: displayName,
    );
    if (result == null || !context.mounted) return;

    try {
      final existing = portfolio.holdings
          .where((h) => h.ticker == ticker.toUpperCase())
          .toList();

      if (existing.isNotEmpty) {
        final h = existing.first;
        final oldShares = h.shares ?? 0.0;
        final oldAvg = h.avgPrice ?? 0.0;
        final newTotalShares = oldShares + result.shares;
        final newAvgPrice = newTotalShares > 0
            ? ((oldShares * oldAvg) + (result.shares * result.avgPrice)) /
                  newTotalShares
            : result.avgPrice;

        await portfolio.addTransaction(
          ticker: ticker,
          type: 'BUY',
          shares: result.shares,
          price: result.avgPrice,
          date: result.date,
        );
        await portfolio.addOrUpdateHolding(
          ticker: ticker,
          shares: newTotalShares,
          avgPrice: newAvgPrice,
        );
      } else {
        await portfolio.addTransaction(
          ticker: ticker,
          type: 'BUY',
          shares: result.shares,
          price: result.avgPrice,
          date: result.date,
        );
        await portfolio.addOrUpdateHolding(
          ticker: ticker,
          shares: result.shares,
          avgPrice: result.avgPrice,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.holdingAdded(ticker))));

      // Show instant advice if available
      final holdingMatch = portfolio.holdings.where(
        (h) => h.ticker == ticker.toUpperCase(),
      );
      if (holdingMatch.isNotEmpty && context.mounted) {
        final holding = holdingMatch.first;
        if (holding.instantAdvice != null) {
          await InstantAdviceSheet.show(context, holding.instantAdvice!);
          return;
        }
      }
      final adviceMatch = portfolio.advice.where(
        (a) => a.ticker == ticker.toUpperCase(),
      );
      if (adviceMatch.isNotEmpty && context.mounted) {
        await InstantAdviceSheet.show(context, adviceMatch.first);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          InterstitialAdHelper.instance.tryShowAd(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.ticker),
          actions: [
            // 보유종목에 추가 버튼
            Consumer<PortfolioProvider>(
              builder: (context, portfolio, child) {
                final isHeld = portfolio.isInHoldings(widget.ticker);
                return IconButton(
                  icon: Icon(
                    isHeld ? Icons.business_center : Icons.add_business,
                  ),
                  tooltip: isHeld
                      ? l10n.alreadyInHoldings
                      : l10n.addToPortfolio,
                  onPressed: () => _onAddToPortfolio(context),
                );
              },
            ),
            // 관심종목 추가/삭제 버튼 (즐겨찾기 시 알림도 자동 구독)
            Consumer<WatchlistProvider>(
              builder: (context, watchlistProvider, child) {
                final isInWatchlist = watchlistProvider.isInWatchlist(
                  widget.ticker,
                );
                return IconButton(
                  icon: Icon(
                    isInWatchlist ? Icons.bookmark : Icons.bookmark_outline,
                  ),
                  tooltip: isInWatchlist
                      ? l10n.removeFromWatchlist
                      : l10n.addToWatchlist,
                  onPressed: () {
                    watchlistProvider.toggleWatchlist(widget.ticker);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isInWatchlist
                              ? l10n.removedFromWatchlist
                              : l10n.addedToWatchlist,
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // 로딩 상태
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 실패 상태 — 종류를 구분해서 보여준다.
    //
    // 개편 전에는 네트워크 끊김·서버 오류·이 종목만 데이터 없음이 **전부
    // 같은 빨간 느낌표 화면**이었다. 사용자가 뭘 해야 할지 알 수 없었고,
    // 데이터 부재를 "오류"로 표기해 멀쩡한 앱을 고장난 것처럼 보이게 했다.
    if (_error != null) {
      return DataUnavailableView.fromError(
        _error!,
        subject: widget.ticker,
        detail: ErrorLocalizer.getMessage(context, _error!),
        onRetry: _loadChartData,
        onReport: _reportDataIssue(context),
        onBack: () => Navigator.of(context).maybePop(),
      );
    }

    // 데이터 없음 — 차트가 비어 있다. 앱 오류가 아니라 **이 종목만**
    // 아직 수집 범위 밖이라는 뜻이다.
    //
    // 개편 전 문구는 `다른 티커를 검색해보세요`였다. 추천 카드를 탭해
    // 들어온 사용자에게 검색 맥락의 안내가 뜨고 있었다.
    if (_chartData == null || _chartData!.data.isEmpty) {
      // 개명·상장폐지면 그 사실을 말한다. 아니면 기존 "준비 중" 화면.
      final r = _resolution;
      if (r != null) {
        final view = DataUnavailableView.fromResolution(
          r,
          onReport: _reportDataIssue(context),
          onBack: () => Navigator.of(context).maybePop(),
          onGoToSuccessor: _goToSuccessor,
        );
        if (view != null) return view;
      }

      return DataUnavailableView(
        kind: UnavailableKind.notReady,
        subject: widget.ticker,
        detail: _freshnessDetail(),
        onReport: _reportDataIssue(context),
        onBack: () => Navigator.of(context).maybePop(),
      );
    }

    // 데이터 표시
    return RefreshIndicator(
      onRefresh: _loadChartData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 헤더 섹션
            TickerHeaderWidget(
              chartData: _chartData!,
              tickerInfo: _tickerInfo,
              onScrollToAIInsight: _scrollToAIInsight,
            ),

            // 카드 사이(12) > 카드 안쪽 블록 간격(≤8). 개편 전엔 8이라
            // 카드 안이 밖보다 넓어 경계가 읽히지 않았다.
            const SizedBox(height: AppDensity.cardGap),

            // 1.5 밸류에이션 카드 (접이식) — 업데이트 날짜 ↔ 전문가 요약 사이
            ValuationCard(metrics: _chartData!.keyMetrics),

            const SizedBox(height: AppDensity.cardGap),

            // 2. 전문가 vs AI 요약 카드
            TickerSummaryCards(
              chartData: _chartData!,
              tickerInfo: _tickerInfo,
              onScrollToAIInsight: _scrollToAIInsight,
            ),

            // 3. Analyst Consensus & Ratings 섹션
            // 애널리스트 헤더는 padding zero이므로 여기서 간격을 준다.
            const SizedBox(height: AppDensity.cardGap),
            TickerAnalystSection(chartData: _chartData!),

            // 4. Calendar Events (earnings, dividends) — tap opens modal
            if (_chartData!.calendar != null)
              EventsCalendarWidget(
                calendar: _chartData!.calendar!,
                earningsHistory: _chartData!.earningsHistory,
              ),

            // 5. 뉴스 카드 (3건 + 감성 통계)
            if (_chartData!.news != null && _chartData!.news!.isNotEmpty ||
                _chartData!.newsSentimentStats != null)
              TickerNewsCard(
                key: _newsKey,
                ticker: widget.ticker,
                items: _chartData!.news ?? [],
                stats: _chartData!.newsSentimentStats,
              ),

            // 6. 배너 광고
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
              const SizedBox(height: AppDensity.sectionGap),
              const BannerAdWidget(),
              const SizedBox(height: AppDensity.sectionGap),
            ],

            // 7. Volume 바 차트
            TickerVolumeChart(
              chartData: _chartData!,
              selectedPeriod: _selectedPeriod,
              periodDays: _periodDays,
            ),

            const SizedBox(height: AppDensity.cardGap),

            // 9. AI Insight 섹션 (마켓랜즈 AI 의견)
            TickerInsightSection(
              chartData: _chartData!,
              aiInsightKey: _aiInsightKey,
            ),

            const SizedBox(height: AppDensity.cardGap),

            // 10. AI 점수 이력 (접힘/펼침)
            TickerScoreSection(chartData: _chartData!),


            // 11. Company Profile (tap opens modal with dividends, valuation, institutional, short)
            CompanyProfileCard(
              profile: _chartData!.profile,
              dividends: _chartData!.dividends,
              keyMetrics: _chartData!.keyMetrics,
              dataPoints: _chartData!.data,
            ),

            // 16. 배너 광고
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
              const SizedBox(height: AppDensity.sectionGap),
              const BannerAdWidget(),
              const SizedBox(height: AppDensity.sectionGap),
            ],

            // 17. Price 차트
            TickerPriceChart(
              chartData: _chartData!,
              selectedPeriod: _selectedPeriod,
              periodDays: _periodDays,
              onPeriodChanged: _onPeriodChanged,
            ),

            const SizedBox(height: AppDensity.cardGap),

            // 18. RSI 차트 (서버 계산 값 시각화)
            RsiChartWidget(dataPoints: _chartData!.data),

            // MACD 차트 - 임시 숨김
            // MacdChartWidget(dataPoints: _chartData!.data),
            const SizedBox(height: AppDensity.sectionGap),

            // 19. 실시간 토크 섹션 (커뮤니티 통합)
            // [COMMUNITY_FLAG] 커뮤니티 비활성화 시 숨김.
            // 복원: FeatureFlags.kCommunityEnabled = true 로 변경.
            if (FeatureFlags.kCommunityEnabled)
              TickerCommunitySection(
                key: _communityKey,
                ticker: widget.ticker,
              ),

            const SizedBox(height: AppDensity.sectionGap),
          ],
        ),
      ),
    );
  }
}
