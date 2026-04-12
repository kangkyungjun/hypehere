import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// RSI / MFI Crossover 차트 위젯
///
/// 서버에서 계산된 RSI, MFI 값을 시각화 (Flutter는 계산 안 함)
/// - MFI 데이터 있으면: RSI-MFI 듀얼 라인 + 크로스오버 fill zone
/// - MFI 데이터 없으면: RSI-only (기존과 동일) graceful fallback
///
/// 참조선: 80 (과매수, green), 20 (과매도, red)
/// 크로스오버 fill:
///   - MFI > RSI (빨간 fill): 매집 (Accumulation)
///   - MFI < RSI (파란 fill): 과열 (Overheated)
class RsiChartWidget extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;

  const RsiChartWidget({
    super.key,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    // RSI 값이 있는 데이터만 필터링
    final rsiData = dataPoints
        .asMap()
        .entries
        .where((e) => e.value.rsi != null)
        .toList();

    if (rsiData.isEmpty) {
      return const SizedBox.shrink();
    }

    // MFI 데이터 존재 여부 확인
    final hasMfi = dataPoints.any((e) => e.mfi != null);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      clipBehavior: Clip.hardEdge,
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
          // 타이틀 (MFI 유무에 따라 변경)
          Text(
            hasMfi ? 'RSI / MFI Crossover' : 'RSI (Relative Strength Index)',
            style: const TextStyle(
              fontSize: AppTypography.headlineMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 차트
          SizedBox(
            height: 150,
            child: hasMfi
                ? _buildCrossoverChart(context, rsiData)
                : _buildRsiOnlyChart(context, rsiData),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 범례
          hasMfi ? _buildCrossoverLegend(context) : _buildRsiOnlyLegend(context),
        ],
      ),
    );
  }

  /// RSI-only 차트 (MFI 없을 때 fallback)
  Widget _buildRsiOnlyChart(BuildContext context, List<MapEntry<int, ChartDataPoint>> rsiData) {
    return LineChart(
      LineChartData(
        gridData: _buildGridData(context),
        titlesData: _buildTitlesData(context),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: context.mlColors.subtleBorder),
        ),
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: dataPoints.length > 1 ? ((dataPoints.length - 1) / 0.6) : 1,
        lineBarsData: [
          LineChartBarData(
            spots: rsiData
                .map((e) => FlSpot(e.key.toDouble(), e.value.rsi!))
                .toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.tertiary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        extraLinesData: _buildExtraLines(context),
      ),
    );
  }

  /// RSI-MFI 크로스오버 차트
  Widget _buildCrossoverChart(BuildContext context, List<MapEntry<int, ChartDataPoint>> rsiData) {
    // MFI 데이터 (인덱스 기반)
    final mfiData = dataPoints
        .asMap()
        .entries
        .where((e) => e.value.mfi != null)
        .toList();

    // 크로스오버 세그먼트 + invisible helper 라인 생성
    final segments = _buildCrossoverSegments();
    final helperBars = <LineChartBarData>[];
    final betweenBars = <BetweenBarsData>[];

    // 메인 라인 인덱스: 0=RSI, 1=MFI, 이후 helper pairs
    int barIndex = 2; // helper 라인 시작 인덱스

    for (final segment in segments) {
      if (segment.points.length < 2) continue;

      // RSI subseries (invisible)
      final rsiHelper = LineChartBarData(
        spots: segment.points
            .map((p) => FlSpot(p.x, p.rsiY))
            .toList(),
        isCurved: true,
        color: Colors.transparent,
        barWidth: 0,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );

      // MFI subseries (invisible)
      final mfiHelper = LineChartBarData(
        spots: segment.points
            .map((p) => FlSpot(p.x, p.mfiY))
            .toList(),
        isCurved: true,
        color: Colors.transparent,
        barWidth: 0,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );

      helperBars.add(rsiHelper);
      helperBars.add(mfiHelper);

      final rsiBarIndex = barIndex;
      final mfiBarIndex = barIndex + 1;
      barIndex += 2;

      betweenBars.add(BetweenBarsData(
        fromIndex: segment.isAccumulation ? mfiBarIndex : rsiBarIndex,
        toIndex: segment.isAccumulation ? rsiBarIndex : mfiBarIndex,
        color: segment.isAccumulation
            ? context.mlColors.lossColor.withValues(alpha: 0.15)
            : context.mlColors.accentBlue.withValues(alpha: 0.15),
      ));
    }

    return LineChart(
      LineChartData(
        gridData: _buildGridData(context),
        titlesData: _buildTitlesData(context),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: context.mlColors.subtleBorder),
        ),
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: dataPoints.length > 1 ? ((dataPoints.length - 1) / 0.6) : 1,
        lineBarsData: [
          // Index 0: RSI 메인 라인
          LineChartBarData(
            spots: rsiData
                .map((e) => FlSpot(e.key.toDouble(), e.value.rsi!))
                .toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.tertiary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Index 1: MFI 메인 라인
          LineChartBarData(
            spots: mfiData
                .map((e) => FlSpot(e.key.toDouble(), e.value.mfi!))
                .toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Helper pairs for fill zones
          ...helperBars,
        ],
        betweenBarsData: betweenBars,
        extraLinesData: _buildExtraLines(context),
      ),
    );
  }

  /// 크로스오버 세그먼트 분할
  List<_CrossoverSegment> _buildCrossoverSegments() {
    final segments = <_CrossoverSegment>[];

    // RSI와 MFI 모두 있는 포인트만 추출
    final paired = <_PairedPoint>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final dp = dataPoints[i];
      if (dp.rsi != null && dp.mfi != null) {
        paired.add(_PairedPoint(
          x: i.toDouble(),
          rsiY: dp.rsi!,
          mfiY: dp.mfi!,
        ));
      }
    }

    if (paired.length < 2) return segments;

    // 첫 포인트로 세그먼트 시작
    bool currentIsAccumulation = paired[0].mfiY >= paired[0].rsiY;
    var currentPoints = <_PairedPoint>[paired[0]];

    for (int i = 1; i < paired.length; i++) {
      final p = paired[i];
      final isAccumulation = p.mfiY >= p.rsiY;

      if (isAccumulation != currentIsAccumulation) {
        // 부호 변경 → 크로스오버 발생
        // 선형 보간으로 교차점 계산
        final prev = paired[i - 1];
        final crossX = _interpolateCrossX(prev, p);
        final crossY = _interpolateCrossY(prev, p, crossX);
        final crossPoint = _PairedPoint(x: crossX, rsiY: crossY, mfiY: crossY);

        // 현재 세그먼트에 교차점 추가 후 닫기
        currentPoints.add(crossPoint);
        segments.add(_CrossoverSegment(
          points: List.from(currentPoints),
          isAccumulation: currentIsAccumulation,
        ));

        // 새 세그먼트 시작 (교차점부터)
        currentIsAccumulation = isAccumulation;
        currentPoints = [crossPoint, p];
      } else {
        currentPoints.add(p);
      }
    }

    // 마지막 세그먼트 닫기
    if (currentPoints.length >= 2) {
      segments.add(_CrossoverSegment(
        points: currentPoints,
        isAccumulation: currentIsAccumulation,
      ));
    }

    return segments;
  }

  /// 선형 보간으로 크로스오버 X 좌표 계산
  double _interpolateCrossX(_PairedPoint a, _PairedPoint b) {
    // diff = mfi - rsi, 부호가 바뀌는 지점
    final diffA = a.mfiY - a.rsiY;
    final diffB = b.mfiY - b.rsiY;
    if ((diffB - diffA).abs() < 0.001) return (a.x + b.x) / 2;
    final t = diffA / (diffA - diffB);
    return a.x + t * (b.x - a.x);
  }

  /// 선형 보간으로 크로스오버 Y 좌표 계산
  double _interpolateCrossY(_PairedPoint a, _PairedPoint b, double crossX) {
    if ((b.x - a.x).abs() < 0.001) return (a.rsiY + b.rsiY) / 2;
    final t = (crossX - a.x) / (b.x - a.x);
    return a.rsiY + t * (b.rsiY - a.rsiY);
  }

  /// 공통 그리드 설정
  FlGridData _buildGridData(BuildContext context) {
    final gridColor = context.mlColors.chartGridLine;
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 20,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: gridColor,
          strokeWidth: 1,
        );
      },
    );
  }

  /// 공통 축 레이블 설정
  FlTitlesData _buildTitlesData(BuildContext context) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 20,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: AppTypography.micro,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: dataPoints.length > 1 ? ((dataPoints.length / 0.6) / 4).ceilToDouble() : 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();

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
                    color: Theme.of(context).colorScheme.outline,
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
    );
  }

  /// 참조선 (80 과매수, 20 과매도)
  ExtraLinesData _buildExtraLines(BuildContext context) {
    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: 80,
          color: context.mlColors.gainColor,
          strokeWidth: 1,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (line) => '80',
            style: TextStyle(
              color: context.mlColors.gainColor,
              fontSize: AppTypography.micro,
            ),
          ),
        ),
        HorizontalLine(
          y: 20,
          color: context.mlColors.lossColor,
          strokeWidth: 1,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (line) => '20',
            style: TextStyle(
              color: context.mlColors.lossColor,
              fontSize: AppTypography.micro,
            ),
          ),
        ),
      ],
    );
  }

  /// RSI-only 범례
  Widget _buildRsiOnlyLegend(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildLegendItem('RSI', Theme.of(context).colorScheme.tertiary),
        _buildDashedLegendItem('80', context.mlColors.gainColor),
        _buildDashedLegendItem('20', context.mlColors.lossColor),
      ],
    );
  }

  /// RSI-MFI 크로스오버 범례
  Widget _buildCrossoverLegend(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildLegendItem('RSI', Theme.of(context).colorScheme.tertiary),
        _buildLegendItem('MFI', Theme.of(context).colorScheme.secondary),
        _buildFillLegendItem('Accumulation', context.mlColors.lossColor.withValues(alpha: 0.3)),
        _buildFillLegendItem('Overheated', context.mlColors.accentBlue.withValues(alpha: 0.3)),
        _buildDashedLegendItem('80', context.mlColors.gainColor),
        _buildDashedLegendItem('20', context.mlColors.lossColor),
      ],
    );
  }

  /// 차트 범례 아이템 (라인)
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  /// 차트 범례 아이템 (fill zone)
  Widget _buildFillLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xxs),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            color: color.withValues(alpha: 1.0),
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }

  /// 차트 범례 아이템 (dashed line)
  Widget _buildDashedLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 2,
          child: CustomPaint(
            painter: _DashedLinePainter(color: color),
          ),
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

/// 크로스오버 세그먼트 (MFI>RSI 또는 MFI<RSI 구간)
class _CrossoverSegment {
  final List<_PairedPoint> points;
  final bool isAccumulation; // true: MFI >= RSI (매집)

  _CrossoverSegment({required this.points, required this.isAccumulation});
}

/// RSI-MFI 페어 포인트
class _PairedPoint {
  final double x;
  final double rsiY;
  final double mfiY;

  _PairedPoint({required this.x, required this.rsiY, required this.mfiY});
}

/// Dashed line painter for legend
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 3.0;
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
