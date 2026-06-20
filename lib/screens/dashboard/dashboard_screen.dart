import 'package:flutter/material.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/treemap_data.dart';
import '../../models/macro_data.dart';
import '../../models/indices_data.dart';
import '../../models/ticker_score.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/charts/macro_banner_widget.dart';
import '../../widgets/dashboard/indices_bar_widget.dart';
import '../../widgets/dashboard/recommendation_grid.dart';
import '../../widgets/dashboard/sector_bar_chart_widget.dart';
import 'sector_overview_screen.dart';
import '../../widgets/common/bento_card.dart';
import '../../theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';
import '../../widgets/common/market_segmented_tabs.dart';
import 'widgets/up_down_tab.dart';
import 'widgets/indexes_tab.dart';
import 'movers_list_screen.dart';
import 'top_stocks_list_screen.dart';
import '../indexes/indexes_detail_screen.dart';
import '../indexes/macro_history_screen.dart';

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

  /// 매크로 지표에서 VIX(VIXCLS) 추출 — 섹터 막대 차트 하단 표시용
  MacroIndicator? get _vixIndicator {
    final list = _macroData?.indicators;
    if (list == null) return null;
    for (final i in list) {
      if (i.indicatorCode == 'VIXCLS') return i;
    }
    return null;
  }

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
        _apiClient.getTopByMarketCap(limit: 5).catchError((e) => e),
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
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          // 플로팅 탭바(extendBody) 뒤로 마지막 콘텐츠가 가리지 않도록 하단 여백 확보
          MediaQuery.of(context).viewPadding.bottom + 64,
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
            const SizedBox(height: AppSpacing.sm),

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
            const SizedBox(height: AppSpacing.sm),

          // ===== Sector Bar Chart Card (탭 → 섹터별 시장현황 트리맵) =====
          BentoCard(
            child: (_treemapError != null && _treemapData == null)
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: TextButton(
                        onPressed: _reloadFilteredData,
                        child: Text(AppLocalizations.of(context).tryAgain),
                      ),
                    ),
                  )
                : (_isTreemapLoading && _treemapData == null)
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SectorBarChartWidget(
                    sectors: _treemapData?.sectors ?? const [],
                    vix: _vixIndicator,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SectorOverviewScreen(
                            initialIndex: _selectedIndex,
                          ),
                        ),
                      );
                    },
                    onVixTap: _vixIndicator == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MacroHistoryScreen(
                                  indicatorCode: 'VIXCLS',
                                  title: 'VIX',
                                ),
                              ),
                            );
                          },
                  ),
          ),

          // ===== 오늘의 추천 종목 그리드 (AI점수 × 오늘 모멘텀 블렌드, 상위 8개) =====
          Builder(
            builder: (_) {
              final recos = RecommendationGrid.compute(_treemapData);
              if (recos.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: RecommendationGrid(
                  items: recos,
                  onTickerTap: _onTickerTap,
                ),
              );
            },
          ),

          // ===== Banner Ad =====
          const SizedBox(height: AppSpacing.sm),
          const Center(child: BannerAdWidget()),

          // ===== Bottom Ad =====
          const SizedBox(height: AppSpacing.sm),
          const Center(child: BannerAdWidget()),
          const SizedBox(height: AppSpacing.sm),
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
        topStocks: _topStocks,
        onTopStocksViewMore: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TopStocksListScreen()),
          );
        },
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
}
