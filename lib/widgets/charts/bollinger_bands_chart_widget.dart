import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';

/// Bollinger Bands 차트 위젯
///
/// 서버에서 계산된 Bollinger Bands 값을 시각화만 수행 (Flutter는 계산 안 함)
/// 구성 요소:
/// - Upper Band (상단 밴드): 서버 계산 값 (bb_upper)
/// - Middle Band (중간선 = 이동평균선): 서버 계산 값 (bb_middle)
/// - Lower Band (하단 밴드): 서버 계산 값 (bb_lower)
/// - Fill Area: Upper ↔ Lower 사이 영역 (변동성 표시)
class BollingerBandsChartWidget extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;

  const BollingerBandsChartWidget({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    // Bollinger Bands 값이 있는 데이터만 필터링
    final bbData = dataPoints
        .asMap()
        .entries
        .where((e) =>
            e.value.bbUpper != null &&
            e.value.bbMiddle != null &&
            e.value.bbLower != null)
        .toList();

    if (bbData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Y축 범위 계산 (가격 데이터 포함)
    final allValues = bbData.expand((e) => [
          e.value.bbUpper!,
          e.value.bbMiddle!,
          e.value.bbLower!,
          if (e.value.close != null) e.value.close!,
        ]);
    final minValue = allValues.fold<double>(
        allValues.first, (prev, curr) => prev < curr ? prev : curr);
    final maxValue = allValues.fold<double>(
        allValues.first, (prev, curr) => prev > curr ? prev : curr);
    final margin = (maxValue - minValue) * 0.1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.md(context.mlColors.overlayDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Text(
            'Bollinger Bands',
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Bollinger Bands 차트
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > minValue ? (maxValue - minValue) / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: context.mlColors.chartGridLine,
                      strokeWidth: AppStroke.thin,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: AppTypography.micro,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        );
                      },
                    ),
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
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: context.mlColors.subtleBorder),
                ),
                minY: minValue - margin,
                maxY: maxValue + margin,
                minX: 0,
                maxX: ((dataPoints.length - 1) / 0.6),  // 40% 미래 영역 확보 (60:40 비율)
                lineBarsData: [
                  // Upper Band (상단 밴드) - 서버 계산 값
                  LineChartBarData(
                    spots: bbData
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.bbUpper!))
                        .toList(),
                    isCurved: true,
                    color: context.mlColors.accentBlue.withValues(alpha: 0.6),
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.mlColors.accentBlue.withValues(alpha: 0.1),
                      cutOffY: bbData.first.value.bbLower!,
                      applyCutOffY: true,
                    ),
                  ),
                  // Middle Band (중간선 = 이동평균선) - 서버 계산 값
                  LineChartBarData(
                    spots: bbData
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.bbMiddle!))
                        .toList(),
                    isCurved: true,
                    color: context.mlColors.accentBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Lower Band (하단 밴드) - 서버 계산 값
                  LineChartBarData(
                    spots: bbData
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.bbLower!))
                        .toList(),
                    isCurved: true,
                    color: context.mlColors.accentBlue.withValues(alpha: 0.6),
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Price Line (종가) - 서버 제공 값
                  if (bbData.every((e) => e.value.close != null))
                    LineChartBarData(
                      spots: bbData
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.close!))
                          .toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.onSurface,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Upper', context.mlColors.accentBlue.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.lg),
              _buildLegendItem('Middle', context.mlColors.accentBlue),
              const SizedBox(width: AppSpacing.lg),
              _buildLegendItem('Lower', context.mlColors.accentBlue.withValues(alpha: 0.6)),
              const SizedBox(width: AppSpacing.lg),
              _buildLegendItem('Price', Theme.of(context).colorScheme.onSurface),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 해석 가이드
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.mlColors.sectionBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).bbInterpretation,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppLocalizations.of(context).bbBandWidth,
                  style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  AppLocalizations.of(context).bbUpperApproach,
                  style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  AppLocalizations.of(context).bbLowerApproach,
                  style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  AppLocalizations.of(context).bbMiddleLine,
                  style: TextStyle(fontSize: AppTypography.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 차트 범례 아이템
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: color,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}
