import 'package:flutter/material.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/treemap_data.dart';
import '../../models/macro_data.dart';
import '../../models/indices_data.dart';
import '../../models/ticker_score.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/charts/treemap_chart_widget.dart';
import '../../widgets/charts/macro_banner_widget.dart';
import '../../widgets/dashboard/indices_bar_widget.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../widgets/common/bento_card.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/coach_mark_overlay.dart';
import '../../widgets/common/market_segmented_tabs.dart';
import '../../providers/coach_mark_provider.dart';
import 'widgets/top_stocks_section.dart';
import 'widgets/up_down_tab.dart';
import 'widgets/indexes_tab.dart';
import 'movers_list_screen.dart';
import 'top_stocks_list_screen.dart';
import '../indexes/indexes_detail_screen.dart';

/// Dashboard Screen - Home 탭 (시장 스냅샷)
///
/// 내부 3탭: Today / Up&Down / Indexes
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();
  late TabController _tabController;

  // Treemap data
  TreemapData? _treemapData;
  bool _isTreemapLoading = false;
  String? _treemapError;

  // Macro indicators
  MacroIndicatorsData? _macroData;

  // Macro signals (yield_curve, m2_liquidity, overall_macro)
  MacroSignalsData? _signalsData;

  // Market indices (S&P, NASDAQ, DOW)
  MarketIndicesData? _indicesData;

  // Top stocks by market cap
  List<TickerScore> _topStocks = [];

  // Index filter state (null=전체, 'SP500', 'DOW30', 'NASDAQ100')
  String? _selectedIndex;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isTreemapLoading = true;
      _error = null;
      _treemapError = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _apiClient.getTreemapData(index: _selectedIndex).catchError((e) => e),
        _apiClient.getMacroIndicators().catchError((e) => e),
        _apiClient.getMacroSignals().catchError((e) => e),
        _apiClient.getMarketIndices().catchError((e) => e),
        _apiClient.getTopTickers(limit: 5).catchError((e) => e),
      ]);

      TreemapData? treemap;
      MacroIndicatorsData? macro;
      MacroSignalsData? signals;
      MarketIndicesData? indices;
      List<TickerScore>? topStocks;
      String? treemapError;

      // Process treemap result
      final treemapResult = results[0];
      if (treemapResult is Exception) {
        treemapError = treemapResult.toString();
      } else {
        treemap = treemapResult as TreemapData;
      }

      // Process macro result
      final macroResult = results[1];
      if (macroResult is! Exception) {
        macro = macroResult as MacroIndicatorsData;
      }

      // Process signals result
      final signalsResult = results[2];
      if (signalsResult is! Exception) {
        signals = signalsResult as MacroSignalsData;
      }

      // Process indices result
      final indicesResult = results[3];
      if (indicesResult is! Exception) {
        indices = indicesResult as MarketIndicesData;
      }

      // Process top stocks result
      final topStocksResult = results[4];
      if (topStocksResult is! Exception) {
        topStocks = topStocksResult as List<TickerScore>;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _treemapData = treemap ?? _treemapData;
          _treemapError = treemapError;
          _isTreemapLoading = false;
          if (macro != null) _macroData = macro;
          if (signals != null) _signalsData = signals;
          if (indices != null) _indicesData = indices;
          if (topStocks != null) _topStocks = topStocks;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorLocalizer.getMessage(context, e);
          _isLoading = false;
          _isTreemapLoading = false;
        });
      }
    }
  }

  void _onIndexFilterChanged(String? index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    _reloadFilteredData();
  }

  /// 필터 변경 시 트리맵만 재로드
  Future<void> _reloadFilteredData() async {
    setState(() {
      _isTreemapLoading = true;
      _treemapError = null;
    });

    try {
      final treemap = await _apiClient.getTreemapData(index: _selectedIndex);
      if (mounted) {
        setState(() {
          _treemapData = treemap;
          _isTreemapLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _treemapError = e.toString();
          _isTreemapLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        MarketSegmentedTabs(
          controller: _tabController,
          tabs: [l10n.tabToday, l10n.tabUpDown, l10n.tabIndexes],
        ),
        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildTodayTab(), _buildUpDownTab(), _buildIndexesTab()],
          ),
        ),
      ],
    );
  }

  /// Today 탭: 매크로 → 지수 → 트리맵 → 시총 Top 3
  Widget _buildTodayTab() {
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        key: const PageStorageKey('dashboard_today'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          // ===== Macro Banner Card =====
          BentoCard(
            padding: EdgeInsets.zero,
            child: MacroBannerWidget(
              data: _macroData,
              signals: _signalsData,
              onNavigateToIndexes: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IndexesDetailScreen(
                      data: _macroData,
                      signals: _signalsData,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_macroData != null || _signalsData != null)
            const SizedBox(height: AppSpacing.xxl),

          // ===== Indices Bar (S&P, NASDAQ, DOW) — individual cards =====
          IndicesBarWidget(
            data: _indicesData,
            selectedIndex: _selectedIndex,
            onIndexTap: (indexCode) {
              // Toggle: tap again to deselect
              final newIndex = _selectedIndex == indexCode ? null : indexCode;
              _onIndexFilterChanged(newIndex);
            },
          ),
          if (_indicesData != null && _indicesData!.indices.isNotEmpty)
            const SizedBox(height: AppSpacing.xxl),

          // ===== Treemap Card (header + chart combined) =====
          CoachMark(
            coachKey: CoachMarkProvider.keyDashboardTreemap,
            message: AppLocalizations.of(context).coachMarkDashboardTreemap,
            child: BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTreemapHeader(),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      AppLocalizations.of(context).treemapLegend,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTreemapSection(),
                ],
              ),
            ),
          ),

          // ===== Banner Ad =====
          const SizedBox(height: AppSpacing.xxl),
          const Center(child: BannerAdWidget()),

          // ===== Top Stocks Card =====
          if (_topStocks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            BentoCard(
              child: TopStocksSection(
                topStocks: _topStocks,
                onTickerTap: _onTickerTap,
                onViewMore: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TopStocksListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],

          // ===== Bottom Ad =====
          const SizedBox(height: AppSpacing.xxl),
          const Center(child: BannerAdWidget()),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Up&Down 탭: 거래대금/상승률/하락률 Top
  Widget _buildUpDownTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: UpDownTab(
        treemapData: _treemapData,
        selectedIndex: _selectedIndex,
        isLoading: _isTreemapLoading,
        onIndexFilterChanged: _onIndexFilterChanged,
        onTickerTap: _onTickerTap,
        onViewMore: (sortBy) {
          if (_treemapData == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MoversListScreen(treemapData: _treemapData!, sortBy: sortBy),
            ),
          );
        },
      ),
    );
  }

  /// Indexes 탭: 거시경제 지표 상세
  Widget _buildIndexesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: IndexesTab(data: _macroData, signals: _signalsData),
    );
  }

  /// 트리맵 섹션
  Widget _buildTreemapSection() {
    if (_isTreemapLoading) {
      return const SizedBox(
        height: 350,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_treemapError != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: context.mlColors.sectionBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 32,
                color: context.mlColors.dangerColor,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _treemapError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: AppTypography.bodyMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadData,
                child: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
        ),
      );
    }
    if (_treemapData == null) return const SizedBox.shrink();

    return TreemapChartWidget(data: _treemapData!, onTickerTap: _onTickerTap);
  }

  /// 트리맵 섹션 헤더 (전체 거래대금 + 변동률 포함)
  Widget _buildTreemapHeader() {
    double totalTrading = 0;
    double weightedChangePct = 0;
    double totalWeight = 0;

    if (_treemapData != null) {
      for (final sector in _treemapData!.sectors) {
        totalTrading += sector.totalTradingValue ?? 0;
        if (sector.avgChangePct != null && sector.totalTradingValue != null) {
          weightedChangePct += sector.avgChangePct! * sector.totalTradingValue!;
          totalWeight += sector.totalTradingValue!;
        }
      }
    }
    final avgPct = totalWeight > 0 ? weightedChangePct / totalWeight : 0.0;
    final tradingStr = formatDollar(totalTrading);

    final mlc = context.mlColors;
    final color = avgPct > 0
        ? mlc.gainColor
        : avgPct < 0
        ? mlc.lossColor
        : mlc.neutralColor;
    final arrow = avgPct > 0
        ? '▲'
        : avgPct < 0
        ? '▼'
        : '─';
    final sign = avgPct >= 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: mlc.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                color: mlc.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                AppLocalizations.of(context).sectorMarketOverview,
                style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tradingStr,
                  style: AppTypography.priceCard.copyWith(
                    color: mlc.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$arrow $sign${avgPct.toStringAsFixed(2)}%',
                  style: AppTypography.numericSecondary.copyWith(
                    color: color,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildIndexFilterChips(),
      ],
    );
  }

  /// 지수 필터 "전체" 칩 (지수 카드 클릭으로 필터 선택, 여기서는 리셋만)
  Widget _buildIndexFilterChips() {
    final l10n = AppLocalizations.of(context);
    final isAllSelected = _selectedIndex == null;

    return GestureDetector(
      onTap: () => _onIndexFilterChanged(null),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isAllSelected
              ? context.mlColors.accentBlue
              : context.mlColors.sectionBackground,
          borderRadius: BorderRadius.circular(AppRadius.badge),
          border: Border.all(
            color: isAllSelected
                ? context.mlColors.accentBlue
                : context.mlColors.subtleBorder,
          ),
        ),
        child: Center(
          child: Text(
            l10n.filterAll,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.semiBold,
              color: isAllSelected
                  ? context.mlColors.onPrimary
                  : context.mlColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
