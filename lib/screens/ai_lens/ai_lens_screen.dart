import 'package:flutter/material.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/ticker_score.dart';
import '../../utils/score_mapper.dart';
import '../../utils/app_page_route.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import 'ai_lens_list_screen.dart';
import 'ai_sector_screen.dart';
import 'chat/ai_chat_screen.dart';
import '../../providers/chat_nav_signals.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/common/market_segmented_tabs.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
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

class _AILensScreenState extends State<AILensScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  // Internal top tabs: AI분석 | AI종목 (default = AI분석/채팅)
  late final TabController _tabController;

  // AI Score distribution + per-segment signal buckets
  Map<ScoreLevel, int> _categoryCounts = {};
  Map<ScoreLevel, List<TickerScore>> _segmentSignals = {};

  // Index filter state
  String? _selectedIndex;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {});
      // 서브탭0=분석(채팅). main.dart가 채팅 페이지에서만 접이식 탭바를 쓰도록 신호.
      aiChatSubTabActive.value = _tabController.index == 0;
    });
    // 초기값 반영(기본 initialIndex=0=분석/채팅 → true).
    aiChatSubTabActive.value = _tabController.index == 0;
    _loadData();
  }

  @override
  void dispose() {
    aiChatSubTabActive.value = false;
    chatNavExpanded.value = false;
    _tabController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _categoryCounts = {};
      _segmentSignals = {};
    });

    try {
      final insights = await _apiClient.getMarketInsights(
        top: 500,
        bottom: 500,
        index: _selectedIndex,
      );

      // Dedupe across top/bottom by ticker
      final seen = <String>{};
      final allSignals = <TickerScore>[];
      for (final s in insights.topMovers) {
        if (seen.add(s.ticker)) allSignals.add(s);
      }
      for (final s in insights.bottomMovers) {
        if (seen.add(s.ticker)) allSignals.add(s);
      }

      // Bucket into the 5 score segments + counts
      final segments = <ScoreLevel, List<TickerScore>>{
        for (final level in ScoreLevel.values) level: <TickerScore>[],
      };
      for (final s in allSignals) {
        segments[ScoreMapper.getScoreLevel(s.score)]!.add(s);
      }
      for (final list in segments.values) {
        list.sort((a, b) => b.score.compareTo(a.score));
      }
      final counts = <ScoreLevel, int>{
        for (final level in ScoreLevel.values) level: segments[level]!.length,
      };

      if (mounted) {
        setState(() {
          _segmentSignals = segments;
          _categoryCounts = counts;
          _isLoading = false;
        });
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

  void _onIndexFilterChanged(String? index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _categoryCounts = {};
      _segmentSignals = {};
    });
    _loadData();
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      appPageRoute(builder: (_) => TickerDetailScreen(ticker: ticker)),
    );
  }

  /// Signals for one score segment.
  List<TickerScore> _segmentItems(ScoreLevel level) {
    return _segmentSignals[level] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          MarketSegmentedTabs(
            controller: _tabController,
            tabs: [l10n.aiTabAnalysis, l10n.aiTabStocks, l10n.aiTabSector],
            // 탭 영역 위아래 여백을 절반 이하로(기본 T8/B12 → T4/B4) 공간 낭비 제거
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const AiChatScreen(),
                RefreshIndicator(onRefresh: _loadData, child: _buildBody()),
                const AiSectorScreen(),
              ],
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        MediaQuery.of(context).viewPadding.bottom + 64,
      ),
      children: [
        // AI Score Section (header + filter + distribution bar)
        BentoCard(child: _buildAIScoreSection()),

        const SizedBox(height: AppSpacing.md),
        const BannerAdWidget(),
        const SizedBox(height: AppSpacing.md),

        // 5 score segments (강력긍정 → 강력부정), banner between each
        for (final entry in _segmentOrder.asMap().entries) ...[
          BentoCard(child: _buildSegmentSection(entry.value)),
          if (entry.key != _segmentOrder.length - 1) ...[
            const SizedBox(height: AppSpacing.md),
            const BannerAdWidget(),
            const SizedBox(height: AppSpacing.md),
          ],
        ],

        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // Display order: strongest positive first → strongest negative last
  static const List<ScoreLevel> _segmentOrder = [
    ScoreLevel.strongBuy,
    ScoreLevel.buy,
    ScoreLevel.hold,
    ScoreLevel.sell,
    ScoreLevel.strongSell,
  ];

  IconData _segmentIcon(ScoreLevel level) {
    switch (level) {
      case ScoreLevel.strongBuy:
      case ScoreLevel.buy:
        return Icons.trending_up;
      case ScoreLevel.hold:
        return Icons.trending_flat;
      case ScoreLevel.sell:
      case ScoreLevel.strongSell:
        return Icons.trending_down;
    }
  }

  Widget _buildSegmentSection(ScoreLevel level) {
    final l10n = AppLocalizations.of(context);
    final colors = context.mlColors;
    final label = ScoreMapper.getLabelForLevelLocalized(level, l10n);
    final color = ScoreMapper.getColorForLevel(level, colors);
    final items = _segmentItems(level);
    final title = '$label (${items.length})';
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
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(_segmentIcon(level), color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.cardTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (items.length > 5)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  appPageRoute(
                    builder: (_) =>
                        AILensListScreen(title: title, items: items),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.seeMore,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.semiBold,
                        color: colors.accentBlue,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colors.accentBlue,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (displayItems.isEmpty)
          _buildEmptyState(l10n.aiNoStocksInSegment)
        else
          ...displayItems.map((ticker) => _buildCompactTickerItem(ticker)),
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
        if (_categoryCounts.isNotEmpty)
          CoachMark(
            coachKey: CoachMarkProvider.keyAiLens,
            message: AppLocalizations.of(context).coachMarkAiLens,
            child: _buildDistributionBar(),
          )
        else
          _buildDistributionSkeleton(),
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
                                fontSize: AppTypography.bodySmall,
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

          const SizedBox(height: AppSpacing.md),

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
              fontSize: AppTypography.bodySmall,
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
              fontSize: AppTypography.bodySmall,
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
                  fontSize: AppTypography.caption,
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

    // Equal-width horizontal segments (전체 / S&P / 나스닥 / 다우)
    final children = <Widget>[];
    for (int i = 0; i < filters.length; i++) {
      final code = filters[i].$1;
      final label = filters[i].$2;
      final isSelected = _selectedIndex == code;
      children.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _onIndexFilterChanged(code),
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.mlColors.infoBg.withValues(alpha: 0.72)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.badge),
                border: Border.all(
                  color: isSelected
                      ? context.mlColors.accentBlue.withValues(alpha: 0.28)
                      : context.mlColors.subtleBorder,
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
        ),
      );
      if (i != filters.length - 1) {
        children.add(const SizedBox(width: AppSpacing.xs));
      }
    }

    return Row(children: children);
  }
}
