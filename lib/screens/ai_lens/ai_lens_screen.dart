import 'package:flutter/material.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/ticker_score.dart';
import '../../utils/score_mapper.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';

/// AI Lens Screen — AI signal analysis extracted from DashboardScreen.
///
/// Shows:
/// - Index filter chips (All / S&P 500 / NASDAQ 100 / DOW 30)
/// - 5-level distribution bar
/// - Top 5 / Bottom 5 side-by-side
/// - Full signal list (lazy loaded, expandable)
class AILensScreen extends StatefulWidget {
  const AILensScreen({super.key});

  @override
  State<AILensScreen> createState() => _AILensScreenState();
}

class _AILensScreenState extends State<AILensScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  // Hero Section
  List<TickerScore> _heroTopSignals = [];
  List<TickerScore> _heroBottomSignals = [];

  // Full Signal List
  List<TickerScore> _fullListSignals = [];

  // AI Score distribution
  Map<ScoreLevel, int> _categoryCounts = {};

  // Index filter state
  String? _selectedIndex;

  // Full list lazy loading
  bool _isFullListLoading = false;
  bool _isFullListLoaded = false;
  int _displayCount = 50;

  bool _isFullSignalExpanded = false;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isFullListLoaded = false;
      _isFullListLoading = false;
      _fullListSignals = [];
      _categoryCounts = {};

      _displayCount = 50;
    });

    try {
      final insights = await _apiClient.getMarketInsights(
        top: 5,
        bottom: 5,
        index: _selectedIndex,
      );

      if (mounted) {
        setState(() {
          _heroTopSignals = insights.topMovers.take(5).toList();
          _heroBottomSignals = insights.bottomMovers.take(5).toList();
          _isLoading = false;
        });
        _loadFullSignals(); // auto-load distribution data
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorLocalizer.getMessage(context, e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFullSignals() async {
    if (_isFullListLoaded || _isFullListLoading) return;
    setState(() => _isFullListLoading = true);

    try {
      final insights = await _apiClient.getMarketInsights(
        top: 500,
        bottom: 500,
        index: _selectedIndex,
      );
      final seen = <String>{};
      final allSignals = <TickerScore>[];
      for (final s in insights.topMovers) {
        if (seen.add(s.ticker)) allSignals.add(s);
      }
      for (final s in insights.bottomMovers) {
        if (seen.add(s.ticker)) allSignals.add(s);
      }

      final categoryCounts = <ScoreLevel, int>{};
      for (final level in ScoreLevel.values) {
        categoryCounts[level] = 0;
      }
      for (final s in allSignals) {
        final level = ScoreMapper.getScoreLevel(s.score);
        categoryCounts[level] = (categoryCounts[level] ?? 0) + 1;
      }

      final fullList = allSignals.length > 10
          ? allSignals.sublist(5, allSignals.length - 5)
          : <TickerScore>[];

      if (mounted) {
        setState(() {
          _fullListSignals = fullList;
          _categoryCounts = categoryCounts;

          _isFullListLoading = false;
          _isFullListLoaded = true;
          _displayCount = 50;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFullListLoading = false);
      }
    }
  }

  void _onIndexFilterChanged(String? index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _isFullListLoaded = false;
      _isFullListLoading = false;
      _fullListSignals = [];
      _categoryCounts = {};

      _displayCount = 50;
    });
    _loadData();
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TickerDetailScreen(ticker: ticker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorStateView(
        message: l10n.signalLoadFailed,
        detail: _error!,
        onRetry: _loadData,
        retryLabel: l10n.tryAgain,
      );
    }

    return ListView(
      key: const PageStorageKey('ai_lens_list'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // AI Score Section
        _buildAIScoreSection(),

        const SizedBox(height: AppSpacing.xxxl),
        const BannerAdWidget(),
        const SizedBox(height: AppSpacing.xxxl),

        // Full Signal List
        GestureDetector(
          onTap: () =>
              setState(() => _isFullSignalExpanded = !_isFullSignalExpanded),
          child: Row(
            children: [
              Icon(Icons.list, color: context.mlColors.accentBlue, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedIndex == null
                          ? l10n.allSignals
                          : _selectedIndex == 'SP500'
                              ? l10n.sp500Signals
                              : _selectedIndex == 'DOW30'
                                  ? l10n.dow30Signals
                                  : l10n.nasdaq100Signals,
                      style: const TextStyle(
                        fontSize: AppTypography.displayMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.marketTrend,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isFullSignalExpanded ? 0.5 : 0,
                duration: AppDuration.fast,
                child: Icon(
                  Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_isFullSignalExpanded) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildFullSignalListSection(),
        ],

        const SizedBox(height: AppSpacing.xxl),
        const BannerAdWidget(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildFullSignalListSection() {
    final l10n = AppLocalizations.of(context);
    if (!_isFullListLoaded) {
      if (!_isFullListLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadFullSignals();
        });
      }
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _selectedIndex == null
                    ? l10n.loadingSignals
                    : _selectedIndex == 'SP500'
                        ? l10n.loadingSP500Signals
                        : _selectedIndex == 'DOW30'
                            ? l10n.loadingDow30Signals
                            : l10n.loadingNasdaq100Signals,
                style: TextStyle(fontSize: AppTypography.bodyMedium, color: context.mlColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    if (_fullListSignals.isEmpty) {
      return _buildEmptyState(l10n.noAdditionalSignals);
    }

    final visibleSignals = _fullListSignals.take(_displayCount).toList();
    final remaining = _fullListSignals.length - _displayCount;

    return Column(
      children: [
        ..._buildSignalListWithAds(visibleSignals),
        if (remaining > 0) _buildLoadMoreButton(remaining),
      ],
    );
  }

  Widget _buildLoadMoreButton(int remaining) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _displayCount += 50),
          icon: const Icon(Icons.expand_more, size: 20),
          label: Text(l10n.showMore(remaining)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSignalListWithAds(List<TickerScore> signals) {
    final List<Widget> widgets = [];
    for (int i = 0; i < signals.length; i++) {
      widgets.add(_buildFullListItem(signals[i]));
      if ((i + 1) % 5 == 0 && i != signals.length - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: BannerAdWidget(),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildFullListItem(TickerScore ticker) {
    final l10n = AppLocalizations.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scoreColor = ticker.scoreColor(context.mlColors);
    final primaryName = isKo ? (ticker.nameKo ?? ticker.name) : ticker.name;
    final secondaryName = isKo ? ticker.name : null;

    return InkWell(
      onTap: () => _onTickerTap(ticker.ticker),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: context.mlColors.subtleBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  ticker.score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.ticker,
                    style: const TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (primaryName != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: primaryName,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              fontWeight: AppTypography.medium,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (secondaryName != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: secondaryName,
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (ticker.signal != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  ticker.signalLabelLocalized(l10n),
                  style: TextStyle(
                    color: context.mlColors.onPrimary,
                    fontSize: AppTypography.micro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: context.mlColors.sectionBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: AppTypography.bodyLarge,
          ),
        ),
      ),
    );
  }

  Widget _buildIndexFilterChips() {
    final l10n = AppLocalizations.of(context);
    final filters = [
      (null, l10n.filterAll),
      ('SP500', 'S&P'),
      ('NASDAQ100', l10n.filterNasdaq),
      ('DOW30', l10n.filterDow),
    ];

    return Row(
      children: filters.map((f) {
        final code = f.$1;
        final label = f.$2;
        final isSelected = _selectedIndex == code;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: GestureDetector(
            onTap: () => _onIndexFilterChanged(code),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : context.mlColors.sectionBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : context.mlColors.subtleBorder,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? context.mlColors.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIScoreSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.tertiary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Text(
              l10n.marketLensAIScore,
              style: const TextStyle(
                fontSize: AppTypography.displayMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildIndexFilterChips(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isFullListLoaded && _categoryCounts.isNotEmpty)
          _buildDistributionBar()
        else if (_isFullListLoading)
          _buildDistributionSkeleton()
        else
          const SizedBox(height: AppSpacing.md),
        const SizedBox(height: AppSpacing.lg),
        _buildSideBySideList(),
      ],
    );
  }

  Widget _buildDistributionBar() {
    final l10n = AppLocalizations.of(context);
    final levels = [
      ScoreLevel.strongBuy,
      ScoreLevel.buy,
      ScoreLevel.hold,
      ScoreLevel.sell,
      ScoreLevel.strongSell,
    ];
    final rangeLabels = ['80~100', '60~79', '40~59', '20~39', '0~19'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: levels.map((level) {
                    final count = _categoryCounts[level] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: count,
                      child: Container(
                        color: ScoreMapper.getColorForLevel(level, context.mlColors),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(levels.length, (i) {
              final level = levels[i];
              final count = _categoryCounts[level] ?? 0;
              final color = ScoreMapper.getColorForLevel(level, context.mlColors);
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ScoreMapper.getLabelForLevelLocalized(level, l10n),
                      style: TextStyle(
                        fontSize: AppTypography.micro,
                        fontWeight: AppTypography.semiBold,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      rangeLabels[i],
                      style: TextStyle(
                        fontSize: AppTypography.chartLabel,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.nItems(count),
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: SizedBox(
          height: 10,
          child: LinearProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildSideBySideList() {
    final l10n = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildHeroColumn(
              label: l10n.topN(_heroTopSignals.length),
              items: _heroTopSignals,
            ),
          ),
          Container(
            width: 1,
            color: context.mlColors.subtleBorder,
          ),
          Expanded(
            child: _buildHeroColumn(
              label: l10n.bottomN(_heroBottomSignals.length),
              items: _heroBottomSignals,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroColumn({
    required String label,
    required List<TickerScore> items,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              AppLocalizations.of(context).noData,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: AppTypography.bodySmall),
            ),
          ),
        if (items.isNotEmpty)
          ...items.map((ticker) => _buildCompactTickerItem(ticker)),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  Widget _buildCompactTickerItem(TickerScore ticker) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scoreColor = ticker.scoreColor(context.mlColors);
    final primaryName = isKo ? (ticker.nameKo ?? ticker.name) : ticker.name;
    final secondaryName = isKo ? ticker.name : null;

    return InkWell(
      onTap: () => _onTickerTap(ticker.ticker),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  ticker.score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.ticker,
                    style: const TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (primaryName != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: primaryName,
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              fontWeight: AppTypography.medium,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (secondaryName != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: secondaryName,
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
