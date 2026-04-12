import 'package:flutter/material.dart';
import '../../services/analytics_api_client.dart';
import '../../utils/error_localizer.dart';
import '../../models/treemap_data.dart';
import '../../models/macro_data.dart';
import '../../models/earnings_data.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/charts/treemap_chart_widget.dart';
import '../../widgets/charts/macro_banner_widget.dart';
import '../../widgets/dashboard/earnings_week_card.dart';
import '../../widgets/dashboard/news_card.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../widgets/common/ml_divider.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/error_state_view.dart';

/// Dashboard Screen - Market 탭 (시장 스냅샷)
///
/// AI 시그널 분석은 AI Lens 탭으로 이동됨.
/// 트리맵, 매크로, 실적, 뉴스 미리보기 표시.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  // Treemap data
  TreemapData? _treemapData;
  bool _isTreemapLoading = false;
  String? _treemapError;

  // Macro indicators
  MacroIndicatorsData? _macroData;

  // Macro signals (yield_curve, m2_liquidity, overall_macro)
  MacroSignalsData? _signalsData;

  // Earnings week data
  EarningsUpcomingData? _earningsData;

  // News items (dashboard preview)
  List<NewsItem> _newsItems = [];

  // Index filter state (null=전체, 'SP500', 'DOW30', 'NASDAQ100')
  String? _selectedIndex;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSignals();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadSignals() async {
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
        _apiClient.getUpcomingEarnings(days: 7).catchError((e) => e),
        _apiClient.getMacroSignals().catchError((e) => e),
        _apiClient.getLatestNews(limit: 3).catchError((e) => e),
      ]);

      TreemapData? treemap;
      MacroIndicatorsData? macro;
      EarningsUpcomingData? earnings;
      MacroSignalsData? signals;
      List<NewsItem>? newsItems;
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

      // Process earnings result
      final earningsResult = results[2];
      if (earningsResult is! Exception) {
        earnings = earningsResult as EarningsUpcomingData;
      }

      // Process signals result
      final signalsResult = results[3];
      if (signalsResult is! Exception) {
        signals = signalsResult as MacroSignalsData;
      }

      // Process news result
      final newsResult = results[4];
      if (newsResult is! Exception) {
        final items = (newsResult as NewsListData).items;
        // bearish 우선 정렬: bearish → neutral → bullish
        items.sort((a, b) {
          const order = {'bearish': 0, 'neutral': 1, 'bullish': 2};
          return (order[a.sentimentGrade] ?? 1).compareTo(order[b.sentimentGrade] ?? 1);
        });
        newsItems = items;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _treemapData = treemap ?? _treemapData;
          _treemapError = treemapError;
          _isTreemapLoading = false;
          if (macro != null) _macroData = macro;
          if (earnings != null) _earningsData = earnings;
          if (signals != null) _signalsData = signals;
          if (newsItems != null) _newsItems = newsItems;
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

  /// 필터 변경 시 트리맵만 재로드 (macro, earnings, news는 유지)
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
    return RefreshIndicator(
      onRefresh: _loadSignals,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);

    // 로딩 상태
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 에러 상태
    if (_error != null) {
      return ErrorStateView(
        message: l10n.signalLoadFailed,
        detail: _error!,
        onRetry: _loadSignals,
        retryLabel: l10n.tryAgain,
      );
    }

    // 데이터 표시
    return ListView(
      key: const PageStorageKey('dashboard_list'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        // ===== Macro Banner (최상단) =====
        MacroBannerWidget(data: _macroData, signals: _signalsData),
        if (_macroData != null || _signalsData != null)
          const SizedBox(height: AppSpacing.xl),

        // ===== Treemap Section =====
        _buildTreemapHeader(),
        const SizedBox(height: AppSpacing.lg),
        _buildTreemapSection(),

        // ===== Earnings Week Card =====
        if (_earningsData != null && _earningsData!.totalCount > 0) ...[
          const MlDivider(),
          EarningsWeekCard(
            data: _earningsData!,
            onTickerTap: _onTickerTap,
          ),
        ],

        // ===== News Card =====
        if (_newsItems.isNotEmpty) ...[
          const MlDivider(),
          NewsCard(
            items: _newsItems,
            onTickerTap: _onTickerTap,
          ),
        ],

        // Banner Ad
        const MlDivider(),
        const BannerAdWidget(),
        const SizedBox(height: AppSpacing.xl),
      ],
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
              Icon(Icons.error_outline, size: 32, color: context.mlColors.dangerColor),
              const SizedBox(height: AppSpacing.md),
              Text(
                _treemapError!,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: AppTypography.bodyMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadSignals,
                child: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
        ),
      );
    }
    if (_treemapData == null) return const SizedBox.shrink();

    return TreemapChartWidget(
      data: _treemapData!,
      onTickerTap: _onTickerTap,
    );
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
    final arrow = avgPct > 0 ? '▲' : avgPct < 0 ? '▼' : '─';
    final sign = avgPct >= 0 ? '+' : '';

    return Row(
      children: [
        Icon(Icons.grid_view, color: context.mlColors.accentBlue, size: 28),
        const SizedBox(width: AppSpacing.md),
        Text(
          AppLocalizations.of(context).sectorMarketOverview,
          style: const TextStyle(fontSize: AppTypography.displayMedium, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildIndexFilterChips(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              tradingStr,
              style: const TextStyle(fontSize: AppTypography.headlineSmall, fontWeight: FontWeight.bold),
            ),
            Text(
              '$arrow $sign${avgPct.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: AppTypography.semiBold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 지수 필터 칩 빌더
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

}
