import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/ticker_score.dart';
import '../../models/treemap_data.dart';
import '../../models/chart_data.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../../config/feature_flags.dart';
import '../../widgets/common/gold_upgrade_sheet.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'widgets/add_holding_sheet.dart';
import 'widgets/instant_advice_sheet.dart';
import 'widgets/watchlist_tab.dart';

/// Watchlist Screen — 관심종목 전용 (보유종목은 별도 HoldingsScreen으로 분리됨)
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  Map<String, TickerScore> _tickerScores = {};
  TreemapData? _treemapData;
  bool _isLoading = true;
  String? _error;

  /// Per-ticker analyst target + 1M/3M-ago prices, derived from getChartData.
  /// Populated progressively after the watchlist loads (see [_loadEnrichment]).
  final Map<String, WatchlistEnrichment> _enrichment = {};

  @override
  void initState() {
    super.initState();
    _loadWatchlistData();
    _loadTreemapData();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final auth = context.read<AuthProvider>();
    final portfolio = context.read<PortfolioProvider>();

    final futures = <Future>[_loadWatchlistData()];
    if (auth.isLoggedIn && portfolio.isInitialized) {
      futures.add(portfolio.refresh());
    }
    await Future.wait(futures);
  }

  Future<void> _loadWatchlistData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Fresh load → drop cached enrichment so it re-derives (e.g. pull-to-refresh).
    _enrichment.clear();

    try {
      final watchlist = context.read<WatchlistProvider>().watchlist;
      if (watchlist.isEmpty) {
        setState(() {
          _tickerScores = {};
          _isLoading = false;
        });
        return;
      }

      final batchScores = await _apiClient.getTickerScoresBatch(watchlist);
      final scoreMap = <String, TickerScore>{};
      for (final ticker in batchScores) {
        scoreMap[ticker.ticker] = ticker;
      }

      setState(() {
        _tickerScores = scoreMap;
        _isLoading = false;
      });

      // Progressive per-ticker enrichment (target + 1M/3M prices). Fire and
      // forget — cards render immediately and fill in as data arrives.
      _loadEnrichment(watchlist);
    } catch (e) {
      setState(() {
        _error = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
  }

  /// Fetch analyst target + 1M/3M-ago prices per ticker via getChartData,
  /// in bounded-concurrency chunks, updating the UI progressively.
  Future<void> _loadEnrichment(List<String> tickers) async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 95));
    final pending =
        tickers.where((t) => !_enrichment.containsKey(t)).toList();
    const chunkSize = 4;

    for (var i = 0; i < pending.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, pending.length);
      final slice = pending.sublist(i, end);

      final results = await Future.wait(slice.map((t) async {
        try {
          final chart =
              await _apiClient.getChartData(t, fromDate: from, toDate: now);
          final points = [...chart.data]
            ..sort((a, b) => a.date.compareTo(b.date));
          return MapEntry(
            t,
            WatchlistEnrichment(
              target: chart.analystConsensus?.mean,
              price1m: _priceAsOf(points, now.subtract(const Duration(days: 30))),
              price3m: _priceAsOf(points, now.subtract(const Duration(days: 90))),
            ),
          );
        } catch (_) {
          return MapEntry(t, const WatchlistEnrichment());
        }
      }));

      if (!mounted) return;
      setState(() {
        for (final e in results) {
          _enrichment[e.key] = e.value;
        }
      });
    }
  }

  /// Close price of the latest data point on or before [target] (ascending list).
  double? _priceAsOf(List<ChartDataPoint> points, DateTime target) {
    double? result;
    for (final p in points) {
      if (p.close == null) continue;
      if (!p.date.isAfter(target)) {
        result = p.close;
      } else {
        break;
      }
    }
    return result;
  }

  Future<void> _loadTreemapData() async {
    try {
      final data = await _apiClient.getTreemapData();
      if (mounted) {
        setState(() => _treemapData = data);
      }
    } catch (e) {
      debugPrint('watchlist treemap error: $e');
    }
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TickerDetailScreen(ticker: ticker),
      ),
    );
  }

  /// Add holding from watchlist: open AddHoldingSheet → BUY transaction.
  Future<void> _onAddHolding(String ticker, TickerScore? score) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => const SignupPromptDialog(),
      );
      if (result == null || !mounted) return;
      if (result == 'login') {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else if (result == 'signup') {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SignupScreen()));
      }
      return;
    }

    // 무료 유저 보유종목 3개 제한 (새 종목만 체크)
    // Hybrid check: server role OR client-side RevenueCat status (webhook 지연 대비)
    // [GOLD_PURCHASE_FLAG] 골드 구매 비활성화 시 Holdings 제한 전체 스킵.
    // 복원: kGoldPurchaseEnabled = true → 3개 제한 + 업그레이드 다이얼로그 자동 복원.
    final portfolio = context.read<PortfolioProvider>();
    final sub = context.read<SubscriptionProvider>();
    final isNewTicker = !portfolio.isInHoldings(ticker);
    if (FeatureFlags.kGoldPurchaseEnabled && isNewTicker && !auth.isGoldOrAbove && !sub.isGoldActive && portfolio.holdings.length >= 3) {
      if (!mounted) return;
      _showHoldingsLimitDialog();
      return;
    }

    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = score != null
        ? (isKo && score.nameKo != null ? score.nameKo! : score.name ?? ticker)
        : ticker;

    final result = await AddHoldingSheet.show(
      context,
      ticker: ticker,
      name: displayName,
    );
    if (result == null || !mounted) return;

    final l10n = AppLocalizations.of(context);

    try {
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.holdingAdded(ticker))),
      );

      // Show instant advice if available
      final holdingMatch = portfolio.holdings.where(
        (h) => h.ticker == ticker.toUpperCase(),
      );
      if (holdingMatch.isNotEmpty && mounted) {
        final holding = holdingMatch.first;
        if (holding.instantAdvice != null) {
          await InstantAdviceSheet.show(context, holding.instantAdvice!);
          return;
        }
      }
      final adviceMatch = portfolio.advice.where((a) => a.ticker == ticker.toUpperCase());
      if (adviceMatch.isNotEmpty && mounted) {
        await InstantAdviceSheet.show(context, adviceMatch.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorLocalizer.getMessage(context, e))),
        );
      }
    }
  }

  Future<void> _showHoldingsLimitDialog() async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber.shade700),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.holdingsLimitTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.holdingsLimitMessage),
            const SizedBox(height: AppSpacing.lg),
            _benefitRow(Icons.all_inclusive, l10n.goldBenefitUnlimitedHoldings, theme),
            _benefitRow(Icons.smart_toy, l10n.goldBenefitAIUnlimited, theme),
            _benefitRow(Icons.block, l10n.goldBenefitNoAds, theme),
          ],
        ),
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

    if (result == 'upgrade' && mounted) {
      GoldUpgradeSheet.show(context, source: 'holdings_limit');
    }
  }

  Widget _benefitRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: AppTypography.bodyMedium, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WatchlistTab(
      tickerScores: _tickerScores,
      enrichment: _enrichment,
      isLoading: _isLoading,
      error: _error,
      treemapData: _treemapData,
      onTickerTap: _onTickerTap,
      onAddHolding: _onAddHolding,
      onRefresh: _loadAllData,
      onRetry: _loadWatchlistData,
    );
  }
}
