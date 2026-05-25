import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_stroke.dart';
import '../../theme/app_typography.dart';

/// Earnings History bar chart widget (EPS estimate vs reported)
///
/// Grouped bars showing:
/// - Grey: EPS Estimate
/// - Green: Beat (reported > estimate)
/// - Red: Miss (reported < estimate)
/// - Surprise % badge on top of each pair
class EarningsChartWidget extends StatelessWidget {
  final List<EarningsHistoryEntry> earningsHistory;
  final EdgeInsetsGeometry? margin;

  const EarningsChartWidget({
    super.key,
    required this.earningsHistory,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (earningsHistory.isEmpty) return const SizedBox.shrink();

    // Filter entries that have at least some data
    final entries = earningsHistory
        .where((e) => e.epsEstimate != null || e.reportedEps != null)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    // Calculate Y range
    double minY = 0;
    double maxY = 0;
    for (final e in entries) {
      final vals = [e.epsEstimate ?? 0, e.reportedEps ?? 0];
      for (final v in vals) {
        if (v < minY) minY = v;
        if (v > maxY) maxY = v;
      }
    }
    final yMargin = (maxY - minY) * 0.25;
    if (yMargin == 0) {
      maxY = maxY + 1;
      minY = minY - 1;
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.mlColors.sectionBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.earningsHistoryEPS,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Legend
          Row(
            children: [
              _buildLegendDot(context, context.mlColors.textTertiary, l10n.earningsEstimate),
              const SizedBox(width: AppSpacing.lg),
              _buildLegendDot(context, context.mlColors.gainColor, l10n.earningsBeat),
              const SizedBox(width: AppSpacing.lg),
              _buildLegendDot(context, context.mlColors.lossColor, l10n.earningsMiss),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Chart
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY + yMargin,
                minY: minY < 0 ? minY - yMargin : 0,
                barGroups: _buildBarGroups(context, entries),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: context.mlColors.chartTooltipBg,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex >= entries.length) return null;
                      final e = entries[groupIndex];
                      final isEstimate = rodIndex == 0;
                      final label = isEstimate ? l10n.earningsEstimate : l10n.earningsActual;
                      final value = isEstimate ? e.epsEstimate : e.reportedEps;
                      if (value == null) return null;
                      String text = '$label: \$${value.toStringAsFixed(2)}';
                      if (!isEstimate && e.surprisePct != null) {
                        text +=
                            '\n${l10n.surpriseLabel}: ${e.surprisePct! >= 0 ? '+' : ''}${e.surprisePct!.toStringAsFixed(1)}%';
                      }
                      return BarTooltipItem(
                        text,
                        TextStyle(
                          color: context.mlColors.onPrimary,
                          fontSize: AppTypography.caption,
                          fontWeight: AppTypography.bold,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      ((maxY + yMargin) - (minY < 0 ? minY - yMargin : 0)) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: context.mlColors.chartGridLine,
                      strokeWidth: AppStroke.hairline,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppTypography.chartLabel,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= entries.length) {
                          return const Text('');
                        }
                        final e = entries[index];
                        // Show date as YYYY-QQ or MM/YY
                        final dateParts = e.date.split('-');
                        String label;
                        if (dateParts.length >= 2) {
                          label = '${dateParts[0].substring(2)}/${dateParts[1]}';
                        } else {
                          label = e.date;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(fontSize: AppTypography.chartLabel),
                              ),
                              // Surprise % below date
                              if (e.surprisePct != null)
                                Text(
                                  '${e.surprisePct! >= 0 ? '+' : ''}${e.surprisePct!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: AppTypography.chartMicro,
                                    fontWeight: AppTypography.bold,
                                    color: e.isBeat
                                        ? context.mlColors.gainColor
                                        : context.mlColors.lossColor,
                                  ),
                                ),
                              if (e.reportedEps == null)
                                Text(
                                  l10n.earningsScheduled,
                                  style: TextStyle(
                                    fontSize: AppTypography.chartMicro,
                                    color: context.mlColors.accentBlue,
                                    fontWeight: AppTypography.medium,
                                  ),
                                ),
                            ],
                          ),
                        );
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
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(BuildContext context, List<EarningsHistoryEntry> entries) {
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;

      final estimateValue = e.epsEstimate ?? 0;
      final reportedValue = e.reportedEps;

      // Determine reported bar color
      Color reportedColor;
      if (reportedValue == null) {
        reportedColor = Colors.transparent;
      } else if (e.isBeat) {
        reportedColor = context.mlColors.gainColor;
      } else {
        reportedColor = context.mlColors.lossColor;
      }

      final barWidth = entries.length > 6 ? 6.0 : 8.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          // Estimate bar (grey)
          BarChartRodData(
            fromY: 0,
            toY: estimateValue,
            color: context.mlColors.textTertiary,
            width: barWidth,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxs)),
          ),
          // Reported bar (green/red)
          if (reportedValue != null)
            BarChartRodData(
              fromY: 0,
              toY: reportedValue,
              color: reportedColor,
              width: barWidth,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppRadius.xxs)),
            ),
        ],
      );
    }).toList();
  }

  Widget _buildLegendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xxs),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.caption,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
