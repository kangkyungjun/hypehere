import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/chart_data.dart';
import '../../models/ticker_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/charts/rsi_chart_widget.dart';
import '../../widgets/charts/company_profile_card.dart';
import '../../widgets/charts/events_calendar_widget.dart';
import '../../widgets/charts/ticker_news_card.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/ads/interstitial_ad_helper.dart';
import '../../widgets/common/ml_divider.dart';
import '../../widgets/common/gold_upgrade_sheet.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/error_state_view.dart';
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
  bool _isLoading = true;
  String? _error;

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

      // Load chart data and ticker info in parallel
      final results = await Future.wait([
        _apiClient.getChartData(
          widget.ticker,
          fromDate: fromDate,
          toDate: toDate,
        ),
        _apiClient.getTickerInfo(widget.ticker),
      ]);

      setState(() {
        _chartData = results[0] as CompleteChartData;
        _tickerInfo = results[1] as TickerInfo;
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
        _error = ErrorLocalizer.getMessage(context, e);
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
    final ticker = widget.ticker;

    // Free user limit check (new ticker only)
    final isNewTicker = !portfolio.isInHoldings(ticker);
    if (isNewTicker && !auth.isGoldOrAbove && portfolio.holdings.length >= 3) {
      if (!context.mounted) return;
      final upgradeResult = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber.shade700),
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
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
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
    final l10n = AppLocalizations.of(context);
    // 로딩 상태
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러 상태
    if (_error != null) {
      return ErrorStateView(
        message: l10n.cannotLoadData,
        detail: _error!,
        onRetry: _loadChartData,
        retryLabel: l10n.tryAgain,
      );
    }

    // 데이터 없음
    if (_chartData == null || _chartData!.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.noData, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.tryDifferentSearch,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
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

            const SizedBox(height: AppSpacing.sm),

            // 2. 전문가 vs AI 요약 카드
            TickerSummaryCards(
              chartData: _chartData!,
              tickerInfo: _tickerInfo,
              onScrollToAIInsight: _scrollToAIInsight,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Divider(
                color: context.mlColors.subtleBorder,
                thickness: 4,
                height: 24,
              ),
            ),

            // 3. Analyst Consensus & Ratings 섹션 (주요일정 위로 이동)
            TickerAnalystSection(chartData: _chartData!),
            const SizedBox(height: AppSpacing.lg),

            // 4. Calendar Events (earnings, dividends) — tap opens modal
            if (_chartData!.calendar != null)
              EventsCalendarWidget(
                calendar: _chartData!.calendar!,
                earningsHistory: _chartData!.earningsHistory,
              ),
            if (_chartData!.calendar != null) const MlDivider(),

            // 5. 뉴스 카드 (3건 + 감성 통계)
            if (_chartData!.news != null && _chartData!.news!.isNotEmpty ||
                _chartData!.newsSentimentStats != null)
              TickerNewsCard(
                key: _newsKey,
                ticker: widget.ticker,
                items: _chartData!.news ?? [],
                stats: _chartData!.newsSentimentStats,
              ),
            if (_chartData!.news != null && _chartData!.news!.isNotEmpty ||
                _chartData!.newsSentimentStats != null)
              const MlDivider(),

            // 6. 배너 광고
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              const BannerAdWidget(),
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              const SizedBox(height: AppSpacing.lg),

            // 7. Volume 바 차트
            TickerVolumeChart(
              chartData: _chartData!,
              selectedPeriod: _selectedPeriod,
              periodDays: _periodDays,
            ),

            const SizedBox(height: AppSpacing.md),

            // 9. AI Insight 섹션 (마켓랜즈 AI 의견)
            TickerInsightSection(
              chartData: _chartData!,
              aiInsightKey: _aiInsightKey,
            ),

            const SizedBox(height: AppSpacing.md),

            // 10. AI 점수 이력 (접힘/펼침)
            TickerScoreSection(chartData: _chartData!),

            const SizedBox(height: AppSpacing.md),

            // 11. Company Profile (tap opens modal with dividends, valuation, institutional, short)
            CompanyProfileCard(
              profile: _chartData!.profile,
              dividends: _chartData!.dividends,
              keyMetrics: _chartData!.keyMetrics,
              dataPoints: _chartData!.data,
            ),
            const SizedBox(height: AppSpacing.md),

            // 16. 배너 광고
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              const BannerAdWidget(),
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              const SizedBox(height: AppSpacing.md),

            // 17. Price 차트
            TickerPriceChart(
              chartData: _chartData!,
              selectedPeriod: _selectedPeriod,
              periodDays: _periodDays,
              onPeriodChanged: _onPeriodChanged,
            ),

            const SizedBox(height: AppSpacing.xxs),

            // 18. RSI 차트 (서버 계산 값 시각화)
            RsiChartWidget(dataPoints: _chartData!.data),

            const SizedBox(height: AppSpacing.md),

            // MACD 차트 - 임시 숨김
            // MacdChartWidget(dataPoints: _chartData!.data),
            const SizedBox(height: AppSpacing.xl),

            // 19. 실시간 토크 섹션 (커뮤니티 통합)
            TickerCommunitySection(key: _communityKey, ticker: widget.ticker),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
