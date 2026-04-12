import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// MACD (Moving Average Convergence Divergence) 차트 위젯
///
/// 서버에서 계산된 MACD 값을 시각화만 수행 (Flutter는 계산 안 함)
/// 구성 요소:
/// - Histogram (히스토그램): MACD - Signal의 차이
/// - MACD Line (파란색): MACD 값
/// - Signal Line (주황색): Signal 값
class MacdChartWidget extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;

  const MacdChartWidget({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    // 🔍 디버그: 필터 전 데이터 확인
    debugPrint('[MACD Debug] === 필터 비교 테스트 ===');
    debugPrint('[MACD Debug] 전체 dataPoints: ${dataPoints.length}개');

    // 📊 기존 필터 (macd + signal + hist 모두 필요)
    final macdDataStrict = dataPoints
        .asMap()
        .entries
        .where((e) =>
            e.value.macd != null &&
            e.value.macdSignal != null &&
            e.value.macdHist != null)
        .toList();

    // 📊 완화 필터 (macd만 필요)
    final macdDataRelaxed = dataPoints
        .asMap()
        .entries
        .where((e) => e.value.macd != null)
        .toList();

    // 📊 signal/hist 둘 다 있는 포인트 개수 (정책 결정용)
    final bothExist = dataPoints.where((d) =>
        d.macdSignal != null && d.macdHist != null).length;

    debugPrint('[MACD Debug] 기존 필터(strict) 결과: ${macdDataStrict.length}개');
    debugPrint('[MACD Debug] 완화 필터(relaxed) 결과: ${macdDataRelaxed.length}개');
    debugPrint('[MACD Debug] signal/hist 둘 다 있는 포인트: $bothExist개');
    debugPrint('[MACD Debug] 필터 차이: ${macdDataRelaxed.length - macdDataStrict.length}개 손실');

    // 📊 날짜별 상세 (최근 15개만)
    final startIdx = dataPoints.length > 15 ? dataPoints.length - 15 : 0;
    debugPrint('\n[MACD Debug] === 최근 15개 데이터 필터 결과 ===');
    for (int i = startIdx; i < dataPoints.length; i++) {
      final dp = dataPoints[i];
      final strictPass = dp.macd != null && dp.macdSignal != null && dp.macdHist != null;
      final relaxedPass = dp.macd != null;

      debugPrint('[MACD Debug] ${dp.date}: '
            'macd=${dp.macd != null ? "O" : "X"} '
            'signal=${dp.macdSignal != null ? "O" : "X"} '
            'hist=${dp.macdHist != null ? "O" : "X"} → '
            'strict=${strictPass ? "✅" : "❌"} relaxed=${relaxedPass ? "✅" : "❌"}');
    }

    // MACD 값이 있는 데이터만 필터링
    final macdData = macdDataStrict;

    if (macdData.isEmpty) {
      debugPrint('[MACD Debug] ⚠️ macdData가 비어있어 SizedBox.shrink() 반환');
      return const SizedBox.shrink();
    }

    // Y축 범위 계산 (통합 - MACD, Signal, Histogram 모두 포함)
    // Step 1: 모든 값 수집
    final allValues = macdData.expand((e) => [
          e.value.macd!,
          e.value.macdSignal!,
          e.value.macdHist!,
        ]);

    // Step 2: min/max 계산
    double minY = allValues.first;
    double maxY = allValues.first;
    for (final v in allValues) {
      if (v < minY) minY = v;
      if (v > maxY) maxY = v;
    }

    // Step 3: 0을 반드시 포함 (MACD 0-line이 중요)
    if (minY > 0) minY = 0;
    if (maxY < 0) maxY = 0;

    // Step 4: 여백 추가 (15%)
    final range = maxY - minY;
    final safeRange = range == 0 ? 1.0 : range; // Division by zero 방지
    final margin = safeRange * 0.15;
    final chartMinY = minY - margin;
    final chartMaxY = maxY + margin;

    // X축 범위 (BarChart와 LineChart 공통)
    final minX = 0.0;
    final maxX = ((macdData.length - 1) / 0.6);  // 40% 미래 영역 확보 (60:40 비율)

    // 디버그 로그
    debugPrint('[MACD Debug] points=${macdData.length}');
    debugPrint('[MACD Debug] X=($minX ~ $maxX)');
    debugPrint('[MACD Debug] unifiedY=($chartMinY ~ $chartMaxY)');
    debugPrint('[MACD Debug] dataRange=(min=$minY, max=$maxY)');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          AppShadow.md(context.mlColors.overlayDim),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Text(
            'MACD (Moving Average Convergence Divergence)',
            style: TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // MACD 차트 (Histogram + Lines)
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                // 1. Histogram (막대 차트) - 서버 계산 값
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    barGroups: List.generate(macdData.length, (index) {
                      final hist = macdData[index].value.macdHist!;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            fromY: 0,
                            toY: hist,
                            color: hist >= 0
                                ? context.mlColors.gainColor.withValues(alpha: 0.3)
                                : context.mlColors.lossColor.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ],
                      );
                    }),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          (chartMaxY - chartMinY) / 4, // 4 grid lines
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: context.mlColors.chartGridLine,
                          strokeWidth: 1,
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
                              value.toStringAsFixed(2),
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
                          interval: ((macdData.length / 0.6) / 4).ceilToDouble(),  // 60:40 비율에 맞춰 간격 조정
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            // 과거 데이터 영역 (왼쪽 60%)
                            if (index >= 0 && index < macdData.length) {
                              final date = macdData[index].value.date;
                              return Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.md),
                                child: Text(
                                  '${date.month}/${date.day}',
                                  style: const TextStyle(fontSize: AppTypography.micro),
                                ),
                              );
                            }

                            // 미래 영역 (오른쪽 40%)
                            if (index >= macdData.length) {
                              final lastDate = macdData.last.value.date;
                              final daysSinceLastDate = index - (macdData.length - 1);
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
                    minY: chartMinY,
                    maxY: chartMaxY,
                  ),
                ),

                // 2. MACD & Signal Lines (오버레이) - 서버 계산 값
                LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: chartMinY,
                    maxY: chartMaxY,
                    minX: minX,
                    maxX: maxX,
                    lineBarsData: [
                      // MACD 라인 (파란색) - 서버 계산 값
                      LineChartBarData(
                        spots: List.generate(
                          macdData.length,
                          (index) => FlSpot(index.toDouble(), macdData[index].value.macd!),
                        ),
                        isCurved: true,
                        color: context.mlColors.accentBlue,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                      // Signal 라인 (주황색) - 서버 계산 값
                      LineChartBarData(
                        spots: List.generate(
                          macdData.length,
                          (index) => FlSpot(index.toDouble(), macdData[index].value.macdSignal!),
                        ),
                        isCurved: true,
                        color: context.mlColors.warningColor,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        // Zero line
                        HorizontalLine(
                          y: 0,
                          color: Theme.of(context).colorScheme.outline,
                          strokeWidth: 1,
                          dashArray: [3, 3],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('MACD', context.mlColors.accentBlue),
              const SizedBox(width: AppSpacing.xl),
              _buildLegendItem('Signal', context.mlColors.warningColor),
              const SizedBox(width: AppSpacing.xl),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: context.mlColors.gainColor.withValues(alpha: 0.3),
                  ),
                  const Text('/', style: TextStyle(fontSize: AppTypography.bodySmall)),
                  Container(
                    width: 12,
                    height: 12,
                    color: context.mlColors.lossColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Histogram',
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
            ],
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
            fontSize: AppTypography.bodySmall,
            color: color,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}
