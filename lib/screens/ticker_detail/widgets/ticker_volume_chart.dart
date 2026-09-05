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

/// Volume 바 차트 위젯 — 양봉(초록)/음봉(빨강) 색상 + 평균선
///
/// ticker_detail_screen.dart의 _buildVolumeChart + _formatVolume 추출.
class TickerVolumeChart extends StatelessWidget {
  final CompleteChartData chartData;
  final String selectedPeriod;
  final Map<String, int> periodDays;

  const TickerVolumeChart({
    super.key,
    required this.chartData,
    required this.selectedPeriod,
    required this.periodDays,
  });

  /// 볼륨 숫자를 읽기 쉽게 포맷 (53200000 → "53.2M")
  static String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dataPoints = chartData.data;

    // volume 데이터가 하나도 없으면 숨김
    final hasVolume = dataPoints.any((d) => d.volume != null && d.volume! > 0);
    if (!hasVolume) return const SizedBox.shrink();

    // 평균 거래량 계산
    final volumes = dataPoints
        .where((d) => d.volume != null && d.volume! > 0)
        .map((d) => d.volume!)
        .toList();
    final avgVolume = volumes.reduce((a, b) => a + b) / volumes.length;

    // 최대 거래량 (Y축 범위)
    final maxVolume = volumes.reduce((a, b) => a > b ? a : b).toDouble();
    final chartMaxY = maxVolume * 1.1; // 10% 여백

    // 바 너비: 데이터 많을수록 얇게
    final barWidth = dataPoints.length > 150
        ? 1.5
        : dataPoints.length > 60
        ? 2.5
        : 4.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더 — 평균 거래량은 trailing 메타로 붙인다.
          // 부모가 가로 xl 패딩을 주므로 가로는 0으로 상쇄.
          SectionHeader(
            title: l10n.volume,
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xs,
            ),
            trailing: Text(
              l10n.averageVolume(_formatVolume(avgVolume.toInt())),
              style: AppTypography.label.copyWith(
                color: context.mlColors.textTertiary,
              ),
            ),
          ),

          // 바 차트
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: context.mlColors.chartBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                barGroups: List.generate(dataPoints.length, (index) {
                  final dp = dataPoints[index];
                  final vol = dp.volume?.toDouble() ?? 0;

                  // 양봉(close>open) → 초록, 음봉 → 빨강, 데이터 없으면 회색
                  Color barColor;
                  if (dp.isBullish) {
                    barColor = context.mlColors.gainColor.withValues(
                      alpha: 0.52,
                    );
                  } else if (dp.isBearish) {
                    barColor = context.mlColors.lossColor.withValues(
                      alpha: 0.52,
                    );
                  } else {
                    barColor = context.mlColors.neutralColor.withValues(
                      alpha: 0.38,
                    );
                  }

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        fromY: 0,
                        toY: vol,
                        color: barColor,
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(1),
                        ),
                      ),
                    ],
                  );
                }),

                // 터치 시 날짜 + 거래량 툴팁
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: context.mlColors.chartTooltipBg,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final index = group.x.toInt();
                      if (index < 0 || index >= dataPoints.length) return null;
                      final dp = dataPoints[index];
                      final date = dp.date;
                      final dateStr = '${date.month}/${date.day}';
                      final volStr = dp.volume != null
                          ? _formatVolume(dp.volume!)
                          : '--';

                      // 거래대금 (close × volume)
                      String tradingValueStr = '';
                      if (dp.close != null && dp.volume != null) {
                        final tradingValue = dp.close! * dp.volume!;
                        tradingValueStr =
                            '\n\$${_formatVolume(tradingValue.toInt())}';
                      }

                      return BarTooltipItem(
                        '$dateStr\n${l10n.volume}: $volStr$tradingValueStr',
                        AppTypography.numericSecondary.copyWith(
                          fontWeight: AppTypography.bold,
                          color: context.mlColors.onPrimary,
                        ),
                      );
                    },
                  ),
                ),

                gridData: const FlGridData(show: false),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        // 최상단/최하단 라벨만 표시
                        if (value <= 0 || value >= chartMaxY * 0.95) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _formatVolume(value.toInt()),
                          // 레퍼런스 축 라벨 11.5dp. 좌축은 폭 제약(48)이라 안전.
                          style: TextStyle(
                            fontSize: AppTypography.caption,
                            color: context.mlColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                borderData: FlBorderData(show: false),

                minY: 0,
                maxY: chartMaxY,

                // 평균 거래량 점선
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avgVolume,
                      color: context.mlColors.textTertiary,
                      strokeWidth: AppStroke.thin,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(show: false),
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
