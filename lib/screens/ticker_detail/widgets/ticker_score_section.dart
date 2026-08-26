import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/chart_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_stroke.dart';
import '../../../theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/common/bento_card.dart';
import '../../../widgets/common/coach_mark_overlay.dart';
import '../../../providers/coach_mark_provider.dart';

class TickerScoreSection extends StatefulWidget {
  final CompleteChartData chartData;

  const TickerScoreSection({super.key, required this.chartData});

  @override
  State<TickerScoreSection> createState() => _TickerScoreSectionState();
}

class _TickerScoreSectionState extends State<TickerScoreSection> {
  bool _showScoreChart = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CoachMark(
      coachKey: CoachMarkProvider.keyTickerScore,
      message: l10n.coachMarkTickerScore,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: BentoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _showScoreChart = !_showScoreChart),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 20,
                      color: context.mlColors.warningColor,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'AI ${l10n.score}',
                      style: TextStyle(
                        fontSize: AppTypography.headlineSmall,
                        fontWeight: AppTypography.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => _showScoreGuide(context, l10n),
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showScoreChart
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
              if (_showScoreChart) _buildScoreChart(),
            ],
          ),
        ),
      ),
    );
  }

  void _showScoreGuide(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiScoreGuideTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aiScoreGuideDescription,
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _scoreRangeRow(
              l10n.aiScoreGuideStrongPositive,
              context.mlColors.gainColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            _scoreRangeRow(
              l10n.aiScoreGuidePositive,
              context.mlColors.gainColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            _scoreRangeRow(
              l10n.aiScoreGuideNeutral,
              Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.xs),
            _scoreRangeRow(
              l10n.aiScoreGuideNegative,
              context.mlColors.lossColor,
            ),
            const SizedBox(height: AppSpacing.xs),
            _scoreRangeRow(
              l10n.aiScoreGuideStrongNegative,
              context.mlColors.lossColor,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Widget _scoreRangeRow(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: AppTypography.bodySmall, color: color),
          ),
        ),
      ],
    );
  }

  /// Score 차트 (독립 좌표계 - Fixed 0-100)
  Widget _buildScoreChart() {
    final dataPoints = widget.chartData.data;
    if (dataPoints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 차트
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: context.mlColors.chartBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20, // 0, 20, 40, 60, 80, 100
                  verticalInterval: ((dataPoints.length / 0.6) / 5)
                      .ceilToDouble(), // 60:40 비율에 맞춰 grid 간격 조정
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: context.mlColors.chartGridLine.withValues(
                        alpha: 0.72,
                      ),
                      strokeWidth: AppStroke.hairline,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: context.mlColors.chartGridLine.withValues(
                        alpha: 0.45,
                      ),
                      strokeWidth: AppStroke.hairline,
                    );
                  },
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: context.mlColors.chartTooltipBg,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt().clamp(
                          0,
                          dataPoints.length - 1,
                        );
                        final date = dataPoints[idx].date;
                        final dateStr = '${date.month}/${date.day}';
                        return LineTooltipItem(
                          '$dateStr\nScore: ${spot.y.toStringAsFixed(1)}',
                          TextStyle(
                            color: context.mlColors.onPrimary,
                            fontWeight: AppTypography.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                titlesData: FlTitlesData(
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
                      reservedSize: 30,
                      interval: ((dataPoints.length / 0.6) / 4)
                          .ceilToDouble(), // 60:40 비율에 맞춰 간격 조정
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        // 과거 데이터 영역 (왼쪽 60%)
                        if (index >= 0 && index < dataPoints.length) {
                          final date = dataPoints[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(
                                fontSize: AppTypography.micro,
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
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              '${futureDate.month}/${futureDate.day}',
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline, // 미래 날짜는 회색으로 구분
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

                // ✅ 핵심: Score는 항상 0-100 고정
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: dataPoints.length > 1
                    ? ((dataPoints.length - 1) / 0.6)
                    : 1,

                lineBarsData: [
                  // Score Line (0-100 범위 유지)
                  LineChartBarData(
                    spots: dataPoints
                        .asMap()
                        .entries
                        .where((e) => e.value.score != null)
                        .map((e) => FlSpot(e.key.toDouble(), e.value.score!))
                        .toList(),
                    isCurved: true,
                    color: context.mlColors.warningColor,
                    barWidth: 2.0,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: context.mlColors.warningColor.withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                ],

                // 수평 참조선 (Strong Buy/Sell 임계값)
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // Strong Buy 라인 (70)
                    HorizontalLine(
                      y: 70,
                      color: context.mlColors.gainColor.withValues(alpha: 0.5),
                      strokeWidth: AppStroke.thin,
                      dashArray: [3, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) => 'Strong Buy (70)',
                        style: TextStyle(
                          color: context.mlColors.gainColor,
                          fontSize: AppTypography.chartLabel,
                        ),
                        alignment: Alignment.topRight,
                      ),
                    ),
                    // Strong Sell 라인 (30)
                    HorizontalLine(
                      y: 30,
                      color: context.mlColors.lossColor.withValues(alpha: 0.5),
                      strokeWidth: AppStroke.thin,
                      dashArray: [3, 3],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (line) => 'Strong Sell (30)',
                        style: TextStyle(
                          color: context.mlColors.lossColor,
                          fontSize: AppTypography.chartLabel,
                        ),
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
