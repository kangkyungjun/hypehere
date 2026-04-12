import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/chart_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_shadow.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
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
      minPrice = prices.fold<double>(prices.first, (prev, curr) => prev < curr ? prev : curr);
      maxPrice = prices.fold<double>(prices.first, (prev, curr) => prev > curr ? prev : curr);
    }
    final priceRange = maxPrice - minPrice;
    final priceMargin = priceRange > 0 ? priceRange * 0.1 : maxPrice * 0.1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (Price + 기간 필터 + 범례)
          Row(
            children: [
              Text(
                'Price',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // 기간 선택 버튼
              ...widget.periodDays.keys.map((period) {
                final isSelected = period == widget.selectedPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => widget.onPeriodChanged(period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.inverseSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.inverseSurface : context.mlColors.subtleBorder,
                        ),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: AppTypography.caption,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? context.mlColors.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // 범례 토글 버튼
              InkWell(
                onTap: () => setState(() => _showLegend = !_showLegend),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Row(
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
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: context.mlColors.accentBlue,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // 차트
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: context.mlColors.chartBackground,
              border: Border.all(color: context.mlColors.subtleBorder),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Stack(
              children: [
                // Price Chart
                LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: priceRange > 0 ? priceRange / 5 : 1,
                  verticalInterval: dataPoints.length > 1 ? ((dataPoints.length / 0.6) / 5).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: context.mlColors.chartGridLine,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: context.mlColors.chartGridLine,
                      strokeWidth: 1,
                    );
                  },
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: context.mlColors.chartTooltipBg,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        // barIndex: 0=Price, 1/2=Trendlines (BB hidden)
                        switch (spot.barIndex) {
                          case 0: // Price (종가)
                            final idx = spot.x.toInt().clamp(0, dataPoints.length - 1);
                            final date = dataPoints[idx].date;
                            final dateStr = '${date.month}/${date.day}';
                            return LineTooltipItem(
                              '$dateStr\n\$${spot.y.toStringAsFixed(2)}',
                              TextStyle(
                                fontSize: AppTypography.bodyLarge,
                                color: context.mlColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            );

                          default: // Trendlines - 툴팁 표시 안함
                            return null;
                        }
                      }).whereType<LineTooltipItem>().toList();
                    },
                  ),
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: TextStyle(
                            fontSize: AppTypography.micro,
                            color: context.mlColors.accentBlue,
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
                      reservedSize: 30,
                      interval: ((dataPoints.length / 0.6) / 4).ceilToDouble(),  // 60:40 비율에 맞춰 간격 조정
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        // 과거 데이터 영역 (왼쪽 60%)
                        if (index >= 0 && index < dataPoints.length) {
                          final date = dataPoints[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(fontSize: AppTypography.micro),
                            ),
                          );
                        }

                        // 미래 영역 (오른쪽 40%)
                        if (index >= dataPoints.length) {
                          final lastDate = dataPoints.last.date;
                          final daysSinceLastDate = index - (dataPoints.length - 1);
                          final futureDate = lastDate.add(Duration(days: daysSinceLastDate));

                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              '${futureDate.month}/${futureDate.day}',
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                color: Theme.of(context).colorScheme.outline,  // 미래 날짜는 회색으로 구분
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

                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: context.mlColors.subtleBorder),
                ),

                minY: minPrice - priceMargin,
                maxY: maxPrice + priceMargin,
                minX: 0,
                maxX: dataPoints.length > 1 ? ((dataPoints.length - 1) / 0.6) : 1,

                lineBarsData: [
                  // Bollinger Bands hidden (kept for future use)
                  // if (dataPoints.any((d) => d.bbUpper != null))
                  //   LineChartBarData( ... ),
                  // if (dataPoints.any((d) => d.bbMiddle != null))
                  //   LineChartBarData( ... ),
                  // if (dataPoints.any((d) => d.bbLower != null))
                  //   LineChartBarData( ... ),

                  // Price Line
                  LineChartBarData(
                    spots: dataPoints
                        .asMap()
                        .entries
                        .where((e) => e.value.close != null)
                        .map((e) => FlSpot(e.key.toDouble(), e.value.close!))
                        .toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.onSurface,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),

                  // 추세선 임시 비활성화 (나중에 재구현 예정)
                  // 저항선 (High Trendline) / 지지선 (Low Trendline)
                ],

                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (latestData.targetPrice != null)
                      HorizontalLine(
                        y: latestData.targetPrice!,
                        color: context.mlColors.gainColor,
                        strokeWidth: 2,
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (line) =>
                              'Target \$${line.y.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: context.mlColors.gainColor,
                            fontSize: AppTypography.micro,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (latestData.stopLoss != null)
                      HorizontalLine(
                        y: latestData.stopLoss!,
                        color: context.mlColors.lossColor,
                        strokeWidth: 2,
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (line) =>
                              'Stop \$${line.y.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: context.mlColors.lossColor,
                            fontSize: AppTypography.micro,
                            fontWeight: FontWeight.bold,
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
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.mlColors.cardBackground.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: context.mlColors.subtleBorder),
                    boxShadow: [
                      AppShadow.md(context.mlColors.overlayDim),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegendItem('Price', Theme.of(context).colorScheme.onSurface),
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
  Widget _buildChartLegendItem(String label, Color color, {bool dashed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: dashed ? null : color,
              border: dashed ? Border(
                top: BorderSide(color: color, width: 1),
              ) : null,
            ),
            child: dashed ? CustomPaint(
              painter: _DashedLinePainter(color),
            ) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.micro,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: AppTypography.medium,
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
