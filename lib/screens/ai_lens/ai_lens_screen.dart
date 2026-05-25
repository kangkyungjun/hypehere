import 'package:flutter/material.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/ticker_score.dart';
import '../../models/stock_classification.dart';
import '../../utils/score_mapper.dart';
import '../../utils/app_page_route.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import 'ai_lens_list_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_duration.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/coach_mark_overlay.dart';
import '../../widgets/common/bento_card.dart';
import '../../providers/coach_mark_provider.dart';

/// AI Lens Screen — AI signal analysis extracted from DashboardScreen.
///
/// Shows:
/// - Index filter chips (All / S&P 500 / NASDAQ 100 / DOW 30)
/// - 5-level distribution bar (28px, equal segments)
/// - Recommended 5 / Caution 5 with "See More" navigation
/// - Full signal list (lazy loaded, expandable)
class AILensScreen extends StatefulWidget {
  const AILensScreen({super.key});

  @override
  State<AILensScreen> createState() => _AILensScreenState();
}

class _AILensScreenState extends State<AILensScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  // Hero Section (top 20 / bottom 20)
  List<TickerScore> _heroTopSignals = [];
  List<TickerScore> _heroBottomSignals = [];

  // Full Signal List
  List<TickerScore> _fullListSignals = [];

  // AI Score distribution
  Map<ScoreLevel, int> _categoryCounts = {};

  // Index filter state
  String? _selectedIndex;

  // Classification filter state
  String? _selectedClassification;
  List<Map<String, dynamic>> _classificationResults = [];
  bool _isLoadingClassification = false;

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
        top: 20,
        bottom: 20,
        index: _selectedIndex,
      );

      if (mounted) {
        setState(() {
          _heroTopSignals = insights.topMovers.take(20).toList();
          _heroBottomSignals = insights.bottomMovers.take(20).toList();
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

  Future<void> _onClassificationTap(String category) async {
    if (_selectedClassification == category) {
      setState(() {
        _selectedClassification = null;
        _classificationResults = [];
      });
      return;
    }
    setState(() {
      _selectedClassification = category;
      _isLoadingClassification = true;
      _classificationResults = [];
    });
    try {
      final results = await _apiClient.getStocksByClassification(category);
      if (!mounted) return;
      setState(() {
        _classificationResults = results;
        _isLoadingClassification = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingClassification = false;
      });
    }
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      appPageRoute(builder: (_) => TickerDetailScreen(ticker: ticker)),
    );
  }

  /// Classification-filtered ticker set (null = no filter)
  Set<String>? get _classificationTickers {
    if (_selectedClassification == null) return null;
    if (_classificationResults.isEmpty) return {};
    return _classificationResults.map((r) => r['ticker'] as String).toSet();
  }

  List<TickerScore> get _filteredHeroTop {
    final tickers = _classificationTickers;
    if (tickers == null) return _heroTopSignals;
    return _heroTopSignals.where((s) => tickers.contains(s.ticker)).toList();
  }

  List<TickerScore> get _filteredHeroBottom {
    final tickers = _classificationTickers;
    if (tickers == null) return _heroBottomSignals;
    return _heroBottomSignals.where((s) => tickers.contains(s.ticker)).toList();
  }

  List<TickerScore> get _filteredFullList {
    final tickers = _classificationTickers;
    if (tickers == null) return _fullListSignals;
    return _fullListSignals.where((s) => tickers.contains(s.ticker)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _loadData, child: _buildBody());
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        // Classification filter chips (최상단)
        _buildClassificationFilterChips(),
        if (_selectedClassification != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildClassificationResultsSection(),
          const SizedBox(height: AppSpacing.xxl),
        ] else
          const SizedBox(height: AppSpacing.md),

        // AI Score Section (header + filter + distribution bar)
        BentoCard(child: _buildAIScoreSection()),

        const SizedBox(height: AppSpacing.xxl),
        const BannerAdWidget(),
        const SizedBox(height: AppSpacing.xxl),

        // Recommended section (top signals)
        BentoCard(
          child: _buildStockSection(
            title: l10n.aiRecommended20(_filteredHeroTop.length),
            items: _filteredHeroTop,
            icon: Icons.trending_up,
            iconColor: context.mlColors.gainColor,
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),
        const BannerAdWidget(),
        const SizedBox(height: AppSpacing.xxl),

        // Caution section (bottom signals)
        BentoCard(
          child: _buildStockSection(
            title: l10n.aiCaution20(_filteredHeroBottom.length),
            items: _filteredHeroBottom,
            icon: Icons.trending_down,
            iconColor: context.mlColors.lossColor,
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Banner before full signal list
        const BannerAdWidget(),
        const SizedBox(height: AppSpacing.xxl),

        // Full Signal List (expandable)
        BentoCard(
          onTap: () =>
              setState(() => _isFullSignalExpanded = !_isFullSignalExpanded),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.mlColors.infoBg.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      Icons.list_rounded,
                      color: context.mlColors.accentBlue,
                      size: 20,
                    ),
                  ),
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
                          style: AppTypography.cardTitle.copyWith(
                            color: context.mlColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.marketTrend,
                          style: AppTypography.label.copyWith(
                            color: context.mlColors.textTertiary,
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
                      color: context.mlColors.textTertiary,
                    ),
                  ),
                ],
              ),
              if (_isFullSignalExpanded) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildFullSignalListSection(),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ─── Classification Filter (최상단) ────────────────────────────

  Widget _buildClassificationFilterChips() {
    final langCode = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: StockClassification.allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = StockClassification.allCategories[index];
          final code = cat['code']!;
          final label = langCode == 'ko' ? cat['ko']! : cat['en']!;
          final isSelected = _selectedClassification == code;
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => _onClassificationTap(code),
            selectedColor: context.mlColors.infoBg.withValues(alpha: 0.72),
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: isSelected
                  ? context.mlColors.accentBlue.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            labelStyle: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.semiBold,
              color: isSelected
                  ? context.mlColors.accentBlue
                  : context.mlColors.textSecondary,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          );
        },
      ),
    );
  }

  Widget _buildClassificationResultsSection() {
    if (_isLoadingClassification) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_classificationResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? '해당 분류 종목이 없습니다'
                : 'No stocks in this category',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final langCode = Localizations.localeOf(context).languageCode;
    final displayItems = _classificationResults.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_selectedClassification ?? ''} (${_classificationResults.length})',
          style: TextStyle(
            fontSize: AppTypography.bodyLarge,
            fontWeight: AppTypography.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...displayItems.map((item) {
          final ticker = item['ticker'] as String;
          final name = item['name'] as String?;
          final nameKo = item['name_ko'] as String?;
          final score = item['score'] as num?;
          final changePct = item['change_pct'] as num?;
          final displayName = (langCode == 'ko' && nameKo != null)
              ? nameKo
              : (name ?? ticker);

          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: context.mlColors.infoBg,
              child: Text(
                ticker[0],
                style: TextStyle(
                  fontSize: 12,
                  color: context.mlColors.accentBlue,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            title: Text(
              ticker,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                if (changePct != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: changePct >= 0
                          ? context.mlColors.gainColor
                          : context.mlColors.lossColor,
                    ),
                  ),
                ],
              ],
            ),
            onTap: () => _onTickerTap(ticker),
          );
        }),
        if (_classificationResults.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '+${_classificationResults.length - 20} more',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  // ─── AI Score Section ──────────────────────────────────────────

  Widget _buildAIScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.mlColors.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: context.mlColors.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                AppLocalizations.of(context).marketLensAIScore,
                style: AppTypography.cardTitle.copyWith(
                  color: context.mlColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildIndexFilterChips(),
        const SizedBox(height: AppSpacing.md),
        if (_isFullListLoaded && _categoryCounts.isNotEmpty)
          CoachMark(
            coachKey: CoachMarkProvider.keyAiLens,
            message: AppLocalizations.of(context).coachMarkAiLens,
            child: _buildDistributionBar(),
          )
        else if (_isFullListLoading)
          _buildDistributionSkeleton()
        else
          const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // ─── Distribution Bar (28px, 5 equal segments) ────────────────

  Widget _buildDistributionBar() {
    final l10n = AppLocalizations.of(context);
    final colors = context.mlColors;

    // Left-to-right: 0→100 (강력부정 → 강력긍정)
    final levels = [
      ScoreLevel.strongSell, // 0-19
      ScoreLevel.sell, // 20-39
      ScoreLevel.hold, // 40-59
      ScoreLevel.buy, // 60-79
      ScoreLevel.strongBuy, // 80-100
    ];
    final boundaryValues = ['0', '20', '40', '60', '80', '100'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          // ── Subtitle explaining score range ──
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.aiScoreSubtitle,
              style: TextStyle(
                fontSize: AppTypography.caption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // ── 28px colored bar with labels inside ──
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              height: 28,
              child: Row(
                children: levels.map((level) {
                  final color = ScoreMapper.getColorForLevel(level, colors);
                  final label = ScoreMapper.getLabelForLevelLocalized(
                    level,
                    l10n,
                  );
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          _showSignalDescription(context, level, color, l10n),
                      child: Container(
                        color: color,
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxs,
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: AppTypography.chartLabel,
                                fontWeight: AppTypography.bold,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Boundary values (0, 20, 40, 60, 80, 100) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              return SizedBox(
                height: 14,
                child: Stack(
                  children: List.generate(boundaryValues.length, (i) {
                    final fraction =
                        i /
                        (boundaryValues.length -
                            1); // 0, 0.2, 0.4, 0.6, 0.8, 1.0
                    final text = boundaryValues[i];
                    final TextAlign align;
                    final double left;
                    if (i == 0) {
                      align = TextAlign.left;
                      left = 0;
                    } else if (i == boundaryValues.length - 1) {
                      align = TextAlign.right;
                      left = totalWidth - 24;
                    } else {
                      align = TextAlign.center;
                      left = totalWidth * fraction - 12;
                    }
                    return Positioned(
                      left: left,
                      width: i == 0 || i == boundaryValues.length - 1 ? 24 : 24,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: AppTypography.chartLabel,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: align,
                      ),
                    );
                  }),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Item counts per segment ──
          Row(
            children: levels.map((level) {
              final count = _categoryCounts[level] ?? 0;
              return Expanded(
                child: Text(
                  l10n.nItems(count),
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Description lines (4 lines with color dots + accessibility icons) ──
          _buildGaugeDescriptionLine(
            color: colors.gainColor,
            text: l10n.gaugeStrongPositiveDesc,
            accessibilityLabel: '\u25B2\u25B2',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildGaugeDescriptionLine(
            color: ScoreMapper.getColorForLevel(ScoreLevel.buy, colors),
            text: l10n.gaugePositiveDesc,
            accessibilityLabel: '\u25B2',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildGaugeDescriptionLine(
            color: ScoreMapper.getColorForLevel(ScoreLevel.sell, colors),
            text: l10n.gaugeNegativeDesc,
            accessibilityLabel: '\u25BC',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildGaugeDescriptionLine(
            color: colors.lossColor,
            text: l10n.gaugeStrongNegativeDesc,
            accessibilityLabel: '\u25BC\u25BC',
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeDescriptionLine({
    required Color color,
    required String text,
    String? accessibilityLabel,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        if (accessibilityLabel != null) ...[
          const SizedBox(width: AppSpacing.xxs),
          Text(
            accessibilityLabel,
            style: TextStyle(
              fontSize: AppTypography.micro,
              color: color,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  void _showSignalDescription(
    BuildContext context,
    ScoreLevel level,
    Color color,
    AppLocalizations l10n,
  ) {
    final String description;
    switch (level) {
      case ScoreLevel.strongBuy:
        description = l10n.aiSignalStrongBuyDesc;
      case ScoreLevel.buy:
        description = l10n.aiSignalBuyDesc;
      case ScoreLevel.hold:
        description = l10n.aiSignalHoldDesc;
      case ScoreLevel.sell:
        description = l10n.aiSignalSellDesc;
      case ScoreLevel.strongSell:
        description = l10n.aiSignalStrongSellDesc;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(description)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.coachMarkGotIt),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: SizedBox(
          height: 28,
          child: LinearProgressIndicator(
            backgroundColor: context.mlColors.sectionBackground,
            color: context.mlColors.accentBlue.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }

  // ─── Stock Section (Recommended / Caution) ─────────────────────

  Widget _buildStockSection({
    required String title,
    required List<TickerScore> items,
    required IconData icon,
    required Color iconColor,
  }) {
    final l10n = AppLocalizations.of(context);
    final displayItems = items.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.cardTitle.copyWith(
                  color: context.mlColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (displayItems.isEmpty) _buildEmptyState(l10n.noData),
        if (displayItems.isNotEmpty) ...[
          ...displayItems.map((ticker) => _buildCompactTickerItem(ticker)),
          if (items.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    appPageRoute(
                      builder: (_) =>
                          AILensListScreen(title: title, items: items),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(l10n.seeMore),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // ─── Full Signal List ──────────────────────────────────────────

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
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: context.mlColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredFullList;
    if (filtered.isEmpty) {
      return _buildEmptyState(l10n.noAdditionalSignals);
    }

    final visibleSignals = filtered.take(_displayCount).toList();
    final remaining = filtered.length - _displayCount;

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
      if ((i + 1) % 10 == 0 && i != signals.length - 1) {
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

  // ─── List Items ────────────────────────────────────────────────

  Widget _buildFullListItem(TickerScore ticker) {
    final l10n = AppLocalizations.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scoreColor = ticker.scoreColor(context.mlColors);
    final primaryName = isKo ? (ticker.nameKo ?? ticker.name) : ticker.name;
    final secondaryName = isKo ? ticker.name : null;

    return InkWell(
      onTap: () => _onTickerTap(ticker.ticker),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.mlColors.subtleBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: Text(
                  ticker.score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: AppTypography.headlineMedium,
                    fontWeight: AppTypography.bold,
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
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.bold,
                      color: context.mlColors.textPrimary,
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
                              color: context.mlColors.textSecondary,
                            ),
                          ),
                          if (secondaryName != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: secondaryName,
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                color: context.mlColors.textTertiary,
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
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  ticker.signalLabelLocalized(l10n),
                  style: TextStyle(
                    color: context.mlColors.onPrimary,
                    fontSize: AppTypography.micro,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.chevron_right,
              color: context.mlColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTickerItem(TickerScore ticker) {
    final l10n = AppLocalizations.of(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scoreColor = ticker.scoreColor(context.mlColors);
    final primaryName = isKo ? (ticker.nameKo ?? ticker.name) : ticker.name;
    final secondaryName = isKo ? ticker.name : null;

    return InkWell(
      onTap: () => _onTickerTap(ticker.ticker),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Center(
                child: Text(
                  ticker.score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: AppTypography.bold,
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
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.bold,
                      color: context.mlColors.textPrimary,
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
                              color: context.mlColors.textSecondary,
                            ),
                          ),
                          if (secondaryName != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: secondaryName,
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                color: context.mlColors.textTertiary,
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
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                ticker.signalLabelLocalized(l10n),
                style: TextStyle(
                  color: scoreColor,
                  fontSize: AppTypography.micro,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              color: context.mlColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Common Widgets ────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final code = f.$1;
          final label = f.$2;
          final isSelected = _selectedIndex == code;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => _onIndexFilterChanged(code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.mlColors.infoBg.withValues(alpha: 0.72)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  border: Border.all(
                    color: isSelected
                        ? context.mlColors.accentBlue.withValues(alpha: 0.28)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.semiBold,
                    color: isSelected
                        ? context.mlColors.accentBlue
                        : context.mlColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
