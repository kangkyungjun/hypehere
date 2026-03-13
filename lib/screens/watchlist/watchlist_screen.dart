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
import 'widgets/holdings_tab.dart';

/// Watchlist Screen — tab-based: 관심종목 | 보유종목
///
/// TabBar + TabBarView structure:
/// ├── WatchlistTab (관심종목 + [+💼] 보유추가)
/// └── HoldingsTab (요약카드 + AI자문 + 보유리스트)
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  Map<String, TickerScore> _tickerScores = {};
  TreemapData? _treemapData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWatchlistData();
    _loadTreemapData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    } catch (_) {}
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TickerDetailScreen(ticker: ticker),
      ),
    );
  }

  /// Add holding from watchlist: open AddHoldingSheet → BUY transaction → switch tab.
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
      // Record BUY transaction
      await portfolio.addTransaction(
        ticker: ticker,
        type: 'BUY',
        shares: result.shares,
        price: result.avgPrice,
        date: result.date,
      );

      // Add/update holding
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
      final holding = portfolio.holdings.firstWhere(
        (h) => h.ticker == ticker.toUpperCase(),
        orElse: () => portfolio.holdings.first,
      );
      if (holding.instantAdvice != null && mounted) {
        await InstantAdviceSheet.show(context, holding.instantAdvice!);
      } else {
        final adviceMatch =
            portfolio.advice.where((a) => a.ticker == ticker.toUpperCase());
        if (adviceMatch.isNotEmpty && mounted) {
          await InstantAdviceSheet.show(context, adviceMatch.first);
        }
      }

      // Switch to holdings tab
      if (mounted) _tabController.animateTo(1);
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        Material(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.tabWatchlist),
              Tab(text: l10n.tabHoldings),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              WatchlistTab(
                tickerScores: _tickerScores,
                isLoading: _isLoading,
                error: _error,
                treemapData: _treemapData,
                onTickerTap: _onTickerTap,
                onAddHolding: _onAddHolding,
                onRefresh: _loadAllData,
                onRetry: _loadWatchlistData,
              ),
              HoldingsTab(
                onTickerTap: _onTickerTap,
                onSwitchToWatchlist: () => _tabController.animateTo(0),
                onRefresh: _loadAllData,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
