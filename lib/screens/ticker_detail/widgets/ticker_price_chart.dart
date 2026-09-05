import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/chart_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_stroke.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/section_header.dart';
import '../../../l10n/app_localizations.dart';

/// Price 차트 위젯 (독립 좌표계 - Auto-scale)
///
/// ticker_detail_screen.dart의 _buildPriceChart + _buildChartLegendItem 추출.
class TickerPriceChart extends StatefulWidget {
  final CompleteChartData chartData;
  final String selectedPeriod;
  final Map<String, int> periodDays;
  final ValueChanged<String> onPeriodChanged;

  const TickerPriceChart({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
    required this.periodDays,
    required this.onPeriodChanged,
  });

  @override
  State<TickerPriceChart> createState() => _TickerPriceChartState();
}

class _TickerPriceChartState extends State<TickerPriceChart> {
  bool _showLegend = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dataPoints = widget.chartData.data;
    if (dataPoints.isEmpty) return const SizedBox.shrink();
    final latestData = dataPoints.last;

    // 가격 범위 계산
    final prices = dataPoints
        .where((d) => d.close != null)
        .map((d) => d.close!)
        .toList()
        .cast<double>();
    double minPrice = 0;
    double maxPrice = 100;
    if (prices.isNotEmpty) {
      minPrice = prices.fold<double>(
        prices.first,
        (prev, curr) => prev < curr ? prev : curr,
      );
      maxPrice = prices.fold<double>(
        prices.first,
        (prev, curr) => prev > curr ? prev : curr,
      );
    }
    final priceRange = maxPrice - minPrice;
    final priceMargin = priceRange > 0 ? priceRange * 0.1 : maxPrice * 0.1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더 — 제목과 기간 칩을 분리한다. 기간 선택은 이 차트만이
          // 아니라 화면 전체 데이터를 다시 받으므로(`_reloadForPeriod`),
          // 제목 줄에 끼워 넣지 않고 차트 바로 위 자기 줄에 둔다.
          SectionHeader(
            title: l10n.priceChartTitle,
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            onTrailingTap: () => setState(() => _showLegend = !_showLegend),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.mlColors.accentBlue,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.legend,
                  style: AppTypography.label.copyWith(
                    color: context.mlColors.accentBlue,
                  ),
                ),
              ],
            ),
          ),

          // 기간 칩 — 선택 상태는 배경색으로 표시한다. 굵기로 표시하면
          // 카드당 w700 예산을 칩 개수만큼 잡아먹는다.
          Row(
            children: [
              ...widget.periodDays.keys.map((period) {
                final isSelected = period == widget.selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => widget.onPeriodChanged(period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.mlColors.textPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isSelected
                              ? context.mlColors.textPrimary
                              : context.mlColors.subtleBorder,
                        ),
                      ),
                      child: Text(
                        period,
                        style: AppTypography.chipLabel.copyWith(
                          color: isSelected
                              ? context.mlColors.onPrimary
                              : context.mlColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 차트
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: context.mlColors.chartBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Stack(
              children: [
                // Price Chart
                LineChart(
                  LineChartData(
                    // 레퍼런스 그리드: **가로선만**, 아주 연하게.
                    // 세로선은 격자를 만들어 곡선의 흐름을 끊는다 — 레퍼런스에 없다.
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: priceRange > 0 ? priceRange / 5 : 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: context.mlColors.chartGridLine,
                          strokeWidth: AppStroke.thin,
                        );
                      },
                    ),

                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: context.mlColors.chartTooltipBg,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots
                              .map((spot) {
                                // barIndex: 0=Price, 1/2=Trendlines (BB hidden)
                                switch (spot.barIndex) {
                                  case 0: // Price (종가)
                                    final idx = spot.x.toInt().clamp(
                                      0,
                                      dataPoints.length - 1,
                                    );
                                    final date = dataPoints[idx].date;
                                    final dateStr = '${date.month}/${date.day}';
                                    return LineTooltipItem(
                                      '$dateStr\n\$${spot.y.toStringAsFixed(2)}',
                                      AppTypography.changeBadge.copyWith(
                                        fontWeight: AppTypography.bold,
                                        color: context.mlColors.onPrimary,
                                      ),
                                    );

                                  default: // Trendlines - 툴팁 표시 안함
                                    return null;
                                }
                              })
                              .whereType<LineTooltipItem>()
                              .toList();
                        },
                      ),
                    ),

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          interval: priceRange > 0 ? priceRange / 5 : null,
                          getTitlesWidget: (value, meta) {
                            // 축 끝값 라벨은 바로 옆 눈금과 겹친다($140 위에 $139).
                            // 간격의 30% 이내로 붙으면 그리지 않는다.
                            final step = priceRange > 0 ? priceRange / 5 : 1;
                            if ((value - meta.min).abs() < step * 0.3 ||
                                (meta.max - value).abs() < step * 0.3) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '\$${value.toInt()}',
                              // 레퍼런스 축 라벨 28.6‰ = 11.5dp. 10은 읽기 어려웠다.
                              // 가로 폭 제약이라 확대해도 클립되지 않는다.
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                color: context.mlColors.textTertiary,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          // 라벨 11px + 상단 패딩 12 + 확대 1.3× 여유.
                          reservedSize: 34,
                          interval: ((dataPoints.length / 0.6) / 4)
                              .ceilToDouble(), // 60:40 비율에 맞춰 간격 조정
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            final mlc = context.mlColors;

                            // 과거 데이터 영역 (왼쪽 60%)
                            if (index >= 0 && index < dataPoints.length) {
                              final date = dataPoints[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: Text(
                                  '${date.month}/${date.day}',
                                  style: TextStyle(
                                    fontSize: AppTypography.caption,
                                    color: mlc.textTertiary,
                                  ),
                                ),
                              );
                            }

                            // 미래 영역 (오른쪽 40%)
                            if (index >= dataPoints.length) {
                              final lastDate = dataPoints.last.date;
                              final daysSinceLastDate =
                                  index - (dataPoints.length - 1);
                              final futureDate = lastDate.add(
                                Duration(days: daysSinceLastDate),
                              );

                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: Text(
                                  '${futureDate.month}/${futureDate.day}',
                                  style: TextStyle(
                                    fontSize: AppTypography.caption,
                                    // 미래 날짜는 한 단계 더 흐리게 구분
                                    color: context.mlColors.textTertiary
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            }

                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),

                    borderData: FlBorderData(show: false),

                    minY: minPrice - priceMargin,
                    maxY: maxPrice + priceMargin,
                    minX: 0,
                    maxX: dataPoints.length > 1
                        ? ((dataPoints.length - 1) / 0.6)
                        : 1,

                    lineBarsData: [
                      // Bollinger Bands hidden (kept for future use)
                      // if (dataPoints.any((d) => d.bbUpper != null))
                      //   LineChartBarData( ... ),
                      // if (dataPoints.any((d) => d.bbMiddle != null))
                      //   LineChartBarData( ... ),
                      // if (dataPoints.any((d) => d.bbLower != null))
                      //   LineChartBarData( ... ),

                      // Price Line — 레퍼런스풍: 굵은 블루 곡선 + 마지막점
                      // 헤일로 강조 + 하단 옅은 블루 필. (방향은 상단 변동배지 담당)
                      LineChartBarData(
                        spots: dataPoints
                            .asMap()
                            .entries
                            .where((e) => e.value.close != null)
                            .map(
                              (e) => FlSpot(e.key.toDouble(), e.value.close!),
                            )
                            .toList(),
                        isCurved: true,
                        // 레퍼런스 계측(화면폭 대비): 라인 13.0‰ = 5.2dp.
                        // 3.0은 얇아서 "굵은 블루 곡선"이라는 인상이 안 났다.
                        curveSmoothness: 0.32,
                        color: context.mlColors.accentBlue,
                        barWidth: 5.0,
                        isStrokeCapRound: true,
                        // 마지막(현재가) 점만 헤일로와 함께 강조 — "여기가 현재".
                        // 계측: 마커 지름 47.6‰ = 19.1dp(반경 9.5),
                        //       헤일로 지름 86.6‰ = 34.8dp(반경 17.4 → stroke 8).
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, bar) =>
                              bar.spots.isNotEmpty &&
                              spot.x == bar.spots.last.x,
                          getDotPainter: (spot, pct, bar, i) =>
                              FlDotCirclePainter(
                                radius: 9.5,
                                color: context.mlColors.accentBlue,
                                strokeWidth: 8,
                                strokeColor: context.mlColors.accentBlue
                                    .withValues(alpha: 0.22),
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: context.mlColors.accentBlue.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),

                      // 추세선 임시 비활성화 (나중에 재구현 예정)
                      // 저항선 (High Trendline) / 지지선 (Low Trendline)
                    ],

                    extraLinesData: ExtraLinesData(
                      // 현재 위치 파란 점선 세로 가이드(레퍼런스: x축까지 내려긋는 선).
                      verticalLines: [
                        if (dataPoints.any((d) => d.close != null))
                          VerticalLine(
                            x: dataPoints
                                .lastIndexWhere((d) => d.close != null)
                                .toDouble(),
                            color: context.mlColors.accentBlue.withValues(
                              alpha: 0.55,
                            ),
                            strokeWidth: 1.7,
                            dashArray: const [5, 5],
                            // 레퍼런스는 점선 하단에 파란 볼드 라벨(`2만km`)을 붙여
                            // "지금 어디인지"를 축에서도 읽게 한다.
                            //
                            // 축 눈금에 강조를 주는 방식은 성립하지 않는다 —
                            // 눈금은 일정 간격으로 찍히고 현재 지점은 그 사이에
                            // 떨어지므로 두 위치가 거의 겹치지 않는다.
                            label: VerticalLineLabel(
                              show: true,
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              style: AppTypography.badgeLabel.copyWith(
                                color: context.mlColors.accentBlue,
                              ),
                              labelResolver: (line) {
                                final d =
                                    dataPoints[dataPoints.lastIndexWhere(
                                          (e) => e.close != null,
                                        )]
                                        .date;
                                return '${d.month}/${d.day}';
                              },
                            ),
                          ),
                      ],
                      horizontalLines: [
                        if (latestData.targetPrice != null)
                          HorizontalLine(
                            y: latestData.targetPrice!,
                            color: context.mlColors.gainColor,
                            strokeWidth: AppStroke.medium,
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (line) =>
                                  'Target \$${line.y.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: context.mlColors.gainColor,
                                fontSize: AppTypography.micro,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                        if (latestData.stopLoss != null)
                          HorizontalLine(
                            y: latestData.stopLoss!,
                            color: context.mlColors.lossColor,
                            strokeWidth: AppStroke.medium,
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (line) =>
                                  'Stop \$${line.y.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: context.mlColors.lossColor,
                                fontSize: AppTypography.micro,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Legend (범례) - 토글 버튼으로 표시/숨김
                if (_showLegend)
                  Positioned(
                    top: 8,
                    right: 8,
                    // 레퍼런스 범례는 차트 우상단에 **박스 없이** 얹힌다
                    // (블루 점 + 뮤트 라벨). 테두리·그림자 상자는 차트 위에
                    // 또 하나의 카드를 만들어 시선을 뺏는다.
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.mlColors.cardBackground.withValues(
                          alpha: 0.85,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildChartLegendItem(
                            'Price',
                            context.mlColors.accentBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 차트 범례 아이템 (Legend)
  Widget _buildChartLegendItem(
    String label,
    Color color, {
    bool dashed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 레퍼런스 범례 마커는 선분이 아니라 **점**(계측 15.2‰ = 6.1dp).
          dashed
              ? SizedBox(
                  width: 16,
                  height: 2,
                  child: CustomPaint(painter: _DashedLinePainter(color)),
                )
              : Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: context.mlColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 점선 페인터 (범례용)
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 2.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
