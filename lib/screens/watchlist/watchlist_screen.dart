import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/ticker_score.dart';
import '../../models/treemap_data.dart';
import '../../widgets/community/signup_prompt_dialog.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../../l10n/app_localizations.dart';
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
    } catch (e) {
      setState(() {
        _error = ErrorLocalizer.getMessage(context, e);
        _isLoading = false;
      });
    }
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
    final portfolio = context.read<PortfolioProvider>();

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

  @override
  Widget build(BuildContext context) {
    return WatchlistTab(
      tickerScores: _tickerScores,
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
