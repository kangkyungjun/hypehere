import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/treemap_data.dart';
import '../../services/analytics_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/charts/treemap_chart_widget.dart';
import '../ticker_detail/ticker_detail_screen.dart';

/// 섹터별 시장현황 화면 (트리맵 + 지수 필터)
///
/// 홈-오늘의 섹터 막대 차트를 탭하면 진입.
/// 상단에 "전체 / S&P / NASDAQ / Dow" 필터(전체 버튼이 제목 옆, 축소형)를 두고
/// 선택에 따라 트리맵을 다시 로드한다. (기존 인라인 트리맵과 기능 동일)
class SectorOverviewScreen extends StatefulWidget {
  const SectorOverviewScreen({super.key, this.initialIndex});

  /// 진입 시 초기 지수 필터 (null=전체, 'SP500'|'NASDAQ100'|'DOW30')
  final String? initialIndex;

  @override
  State<SectorOverviewScreen> createState() => _SectorOverviewScreenState();
}

class _SectorOverviewScreenState extends State<SectorOverviewScreen> {
  final AnalyticsApiClient _apiClient = AnalyticsApiClient();

  String? _selectedIndex;
  TreemapData? _data;
  bool _isLoading = true;
  String? _error;

  // (코드, 라벨) — 전체는 l10n, 지수는 고유명사
  static const List<({String? code, String label})> _filters = [
    (code: null, label: '_all_'),
    (code: 'SP500', label: 'S&P 500'),
    (code: 'NASDAQ100', label: 'NASDAQ'),
    (code: 'DOW30', label: 'Dow'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _load();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiClient.getTreemapData(index: _selectedIndex);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterTap(String? code) {
    if (_selectedIndex == code) return;
    setState(() => _selectedIndex = code);
    _load();
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TickerDetailScreen(ticker: ticker)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.mlColors.sectionBackground,
      appBar: AppBar(title: Text(l10n.sectorMarketOverview)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow(l10n),
          _buildSummaryLine(),
          Expanded(child: _buildTreemap(l10n)),
        ],
      ),
    );
  }

  /// 지수 필터 칩 행 (전체 + 지수들, 축소형)
  Widget _buildFilterRow(AppLocalizations l10n) {
    final mlc = context.mlColors;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final selected = _selectedIndex == f.code;
          final label = f.label == '_all_' ? l10n.filterAll : f.label;
          return GestureDetector(
            onTap: () => _onFilterTap(f.code),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? mlc.infoBg.withValues(alpha: 0.72)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.badge),
                border: Border.all(
                  color: selected
                      ? mlc.accentBlue.withValues(alpha: 0.28)
                      : mlc.subtleBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  fontWeight: AppTypography.semiBold,
                  color: selected ? mlc.accentBlue : mlc.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 전체 거래대금 + 가중 변동률 요약
  Widget _buildSummaryLine() {
    final mlc = context.mlColors;
    if (_data == null) return const SizedBox.shrink();

    double totalTrading = 0;
    double weighted = 0;
    double weight = 0;
    for (final s in _data!.sectors) {
      totalTrading += s.totalTradingValue ?? 0;
      if (s.avgChangePct != null && s.totalTradingValue != null) {
        weighted += s.avgChangePct! * s.totalTradingValue!;
        weight += s.totalTradingValue!;
      }
    }
    final avg = weight > 0 ? weighted / weight : 0.0;
    final color = avg > 0
        ? mlc.gainColor
        : avg < 0
        ? mlc.lossColor
        : mlc.neutralColor;
    final arrow = avg > 0 ? '▲' : avg < 0 ? '▼' : '─';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // 거래대금 값: 커질 수 있으니 축소 방어(FittedBox), 값은 진한색
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatDollar(totalTrading),
                style: AppTypography.numericSecondary.copyWith(
                  color: mlc.textPrimary,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$arrow ${avg >= 0 ? '+' : ''}${avg.toStringAsFixed(2)}%',
            style: AppTypography.numericSecondary.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTreemap(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: context.mlColors.dangerColor),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: _load, child: Text(l10n.tryAgain)),
          ],
        ),
      );
    }
    if (_data == null || _data!.sectors.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: TreemapChartWidget(data: _data!, onTickerTap: _onTickerTap),
    );
  }
}
