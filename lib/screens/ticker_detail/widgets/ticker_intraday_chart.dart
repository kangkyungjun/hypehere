import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/chart_data.dart';
import '../../../models/intraday_chart.dart';
import '../../../services/analytics_api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_shadow.dart';

/// 종목 상세 페이지의 단기 차트 — 1h(시간봉) ↔ 1d(최근 7일 일봉) 토글.
///
/// - 1h: 가장 최근 거래일의 정규장 09:30~16:00 ET 시간봉.
///       장중엔 형성된 봉만(왼쪽부터 채워짐), 장외엔 직전 거래일 7봉 풀.
/// - 1d: 최근 7거래일 일봉(기존 메인 차트 데이터의 마지막 7개 재사용).
/// - 1d 모드에서 점 탭 → 그 일자의 1h 차트로 드릴다운.
/// - 가로 풀 사용(좌우 패딩 없음).
class TickerIntradayChart extends StatefulWidget {
  const TickerIntradayChart({
    super.key,
    required this.ticker,
    required this.dailyData,
  });

  /// 종목 티커.
  final String ticker;

  /// 기존 메인 차트의 일봉 데이터(최근 7일 일봉 모드용 재사용 — 추가 API 호출 X).
  final List<ChartDataPoint> dailyData;

  @override
  State<TickerIntradayChart> createState() => _TickerIntradayChartState();
}

enum _Mode { intraday, daily }

class _TickerIntradayChartState extends State<TickerIntradayChart> {
  final AnalyticsApiClient _api = AnalyticsApiClient();

  _Mode _mode = _Mode.intraday;
  IntradayChartData? _intraday;
  bool _loading = false;
  String? _error;

  /// 드릴다운 일자(ET, 'YYYY-MM-DD'). null이면 '최신 거래일' 모드.
  String? _drilldownDate;

  @override
  void initState() {
    super.initState();
    _loadIntraday();
  }

  Future<void> _loadIntraday({String? dateEt}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getIntradayChartData(
        widget.ticker,
        dateEt: dateEt,
      );
      if (!mounted) return;
      setState(() {
        _intraday = data;
        _drilldownDate = dateEt;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _switchTo(_Mode m) {
    if (_mode == m && _drilldownDate == null) return;
    setState(() {
      _mode = m;
      // 1d 모드로 갈 땐 드릴다운 컨텍스트 해제.
      if (m == _Mode.daily) _drilldownDate = null;
    });
  }

  void _drilldownToDate(String dateEt) {
    setState(() => _mode = _Mode.intraday);
    _loadIntraday(dateEt: dateEt);
  }

  void _backToLatestIntraday() {
    if (_drilldownDate == null) return;
    _loadIntraday();
  }

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    // 카드 컨테이너만 패딩 — 차트 영역은 가로 풀.
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      // 앱의 카드 언어는 무테 + 그림자다. 테두리 박스는 다른 카드들과
      // 나란히 놓였을 때 혼자 낡아 보인다.
      decoration: BoxDecoration(
        color: mlc.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.card(Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (제목 + 토글). 패딩 있음.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildHeader(mlc),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 보조 안내 줄.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildSubtitle(mlc),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 차트 영역 — 가로 풀(좌우 패딩 없음).
          SizedBox(height: 180, child: _buildChartArea(mlc)),
        ],
      ),
    );
  }

  Widget _buildHeader(MarketLensColors mlc) {
    return Row(
      children: [
        Text(
          _drilldownDate != null
              ? 'Intraday · $_drilldownDate'
              : 'Intraday',
          style: AppTypography.cardTitle.copyWith(color: mlc.textPrimary),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (_drilldownDate != null)
          TextButton.icon(
            onPressed: _backToLatestIntraday,
            icon: const Icon(Icons.arrow_back_rounded, size: 14),
            label: Text(AppLocalizations.of(context).chartLatest),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        const Spacer(),
        _toggleButton('1h', _mode == _Mode.intraday, () => _switchTo(_Mode.intraday)),
        const SizedBox(width: AppSpacing.xs),
        _toggleButton('1d', _mode == _Mode.daily, () => _switchTo(_Mode.daily)),
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    final mlc = context.mlColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: selected ? mlc.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? mlc.accentBlue : mlc.subtleBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.caption,
            fontWeight: selected ? AppTypography.bold : AppTypography.regular,
            color: selected
                ? mlc.onPrimary
                : mlc.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(MarketLensColors mlc) {
    final style = AppTypography.label.copyWith(color: mlc.textTertiary);
    if (_mode == _Mode.daily) {
      return Text(AppLocalizations.of(context).intradayHint, style: style);
    }
    final dateEt = _intraday?.latestDateEt;
    if (dateEt == null) {
      return Text(AppLocalizations.of(context).marketHoursHint, style: style);
    }
    return Text('$dateEt · 미국 장중 09:30~16:00 ET', style: style);
  }

  Widget _buildChartArea(MarketLensColors mlc) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).cannotLoadData,
          style: TextStyle(color: mlc.dangerColor),
        ),
      );
    }
    if (_mode == _Mode.daily) {
      return _buildDailyChart(mlc);
    }
    return _buildIntradayChart(mlc);
  }

  // ── 1h 차트 ─────────────────────────────────────────────────
  Widget _buildIntradayChart(MarketLensColors mlc) {
    final bars = _intraday?.data ?? const [];
    if (bars.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noIntradayData,
          style: AppTypography.label.copyWith(color: mlc.textTertiary),
        ),
      );
    }
    // X축: 09:30 ~ 16:00 ET 7봉 슬롯. 봉이 있는 슬롯만 라인 연결.
    // 슬롯은 [9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5] (1봉=시작시각).
    final slots = <double>[9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5];
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;
    for (final bar in bars) {
      final close = bar.close;
      if (close == null) continue;
      // ET 시·분을 직접 사용 — DateTime.parse → 로컬 TZ 환산 시
      // hourSlot이 slot 범위(9.5~15.5)를 벗어나 plot 밖으로 그려짐.
      final hourSlot = bar.etHour + bar.etMinute / 60.0;
      spots.add(FlSpot(hourSlot, close));
      if (close < minY) minY = close;
      if (close > maxY) maxY = close;
    }
    if (spots.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noIntradayData,
          style: AppTypography.label.copyWith(color: mlc.textTertiary),
        ),
      );
    }
    // 상단 가격 라벨이 잘리지 않도록 위 패딩 여유.
    final pad = (maxY - minY).abs() * 0.18;
    final yMin = (minY - pad * 0.4).clamp(0.0, double.infinity);
    final yMax = maxY + pad;

    final firstClose = spots.first.y;
    final lastClose = spots.last.y;
    final lineColor = lastClose >= firstClose ? mlc.gainColor : mlc.lossColor;

    final lineBars = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: false,
        color: lineColor,
        // Tier 2(보조 차트) — 히어로인 일봉 차트(5.0)보다 얇게 유지해야
        // 화면 안에서 위계가 선다. 색은 방향성(당일 시가 대비)이라 녹/적.
        barWidth: 2.5,
        // 전 지점에 점을 찍으면 분봉에서는 선이 점으로 뭉개진다.
        // 레퍼런스처럼 **현재 지점만** 헤일로와 함께 표시한다.
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, bar) =>
              bar.spots.isNotEmpty && spot.x == bar.spots.last.x,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 5,
            color: lineColor,
            strokeWidth: 4,
            strokeColor: lineColor.withValues(alpha: 0.22),
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: lineColor.withValues(alpha: 0.12),
        ),
        showingIndicators: List<int>.generate(spots.length, (i) => i),
      ),
    ];

    return LineChart(
      LineChartData(
        minX: 9.5,
        maxX: 16.0,
        minY: yMin,
        maxY: yMax,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // 슬롯 시각만 라벨 노출.
                if (!slots.any((s) => (s - value).abs() < 0.05)) {
                  return const SizedBox.shrink();
                }
                final h = value.floor();
                final m = ((value - h) * 60).round();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: mlc.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touched) => touched.map((s) => LineTooltipItem(
                  '\$${s.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: lineColor,
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.bold,
                  ),
                )).toList(),
          ),
          getTouchedSpotIndicator: (barData, indicators) => indicators
              .map((_) => TouchedSpotIndicatorData(
                    const FlLine(color: Colors.transparent),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 2.5,
                        color: lineColor,
                        strokeWidth: 0,
                      ),
                    ),
                  ))
              .toList(),
        ),
        lineBarsData: lineBars,
        showingTooltipIndicators: List<ShowingTooltipIndicators>.generate(
          spots.length,
          (i) => ShowingTooltipIndicators(
            [LineBarSpot(lineBars[0], 0, spots[i])],
          ),
        ),
      ),
    );
  }

  // ── 1d 차트 (최근 7거래일, 점 탭 시 드릴다운) ────────────────────
  Widget _buildDailyChart(MarketLensColors mlc) {
    // 일봉 중 가장 최근 7개만 사용.
    final all = widget.dailyData
        .where((d) => d.close != null)
        .toList();
    if (all.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noDailyData,
          style: AppTypography.label.copyWith(color: mlc.textTertiary),
        ),
      );
    }
    final start = all.length > 7 ? all.length - 7 : 0;
    final recent = all.sublist(start);
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;
    for (var i = 0; i < recent.length; i++) {
      final y = recent[i].close!;
      spots.add(FlSpot(i.toDouble(), y));
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    // 상단 가격 라벨이 잘리지 않도록 위 패딩 여유.
    final pad = (maxY - minY).abs() * 0.18;
    final yMin = (minY - pad * 0.4).clamp(0.0, double.infinity);
    final yMax = maxY + pad;

    final firstClose = spots.first.y;
    final lastClose = spots.last.y;
    final lineColor = lastClose >= firstClose ? mlc.gainColor : mlc.lossColor;

    final lineBars = <LineChartBarData>[
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.28,
        color: lineColor,
        barWidth: 2.5,
        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, bar) =>
              bar.spots.isNotEmpty && spot.x == bar.spots.last.x,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 5,
            color: lineColor,
            strokeWidth: 4,
            strokeColor: lineColor.withValues(alpha: 0.22),
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: lineColor.withValues(alpha: 0.12),
        ),
        showingIndicators: List<int>.generate(spots.length, (i) => i),
      ),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (recent.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= recent.length) {
                  return const SizedBox.shrink();
                }
                final d = recent[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: mlc.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touched) => touched.map((s) => LineTooltipItem(
                  '\$${s.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: lineColor,
                    fontSize: AppTypography.caption,
                    fontWeight: AppTypography.bold,
                  ),
                )).toList(),
          ),
          getTouchedSpotIndicator: (barData, indicators) => indicators
              .map((_) => TouchedSpotIndicatorData(
                    const FlLine(color: Colors.transparent),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: mlc.onPrimary,
                      ),
                    ),
                  ))
              .toList(),
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response != null &&
                response.lineBarSpots != null &&
                response.lineBarSpots!.isNotEmpty) {
              final idx = response.lineBarSpots!.first.x.round();
              if (idx >= 0 && idx < recent.length) {
                final d = recent[idx].date;
                final iso =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                _drilldownToDate(iso);
              }
            }
          },
        ),
        lineBarsData: lineBars,
        showingTooltipIndicators: List<ShowingTooltipIndicators>.generate(
          spots.length,
          (i) => ShowingTooltipIndicators(
            [LineBarSpot(lineBars[0], 0, spots[i])],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
