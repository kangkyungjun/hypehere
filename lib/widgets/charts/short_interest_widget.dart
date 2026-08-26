import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 공매도 위젯
///
/// 서버 제공 필드: shortRatio (Days to Cover), shortPercentFloat (Short % of Float)
/// 최신 유효 데이터 포인트에서 추출하여 카드 형태로 표시
/// 하단에 short interest 수준 상태 표시
class ShortInterestWidget extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final EdgeInsetsGeometry? margin;

  const ShortInterestWidget({
    super.key,
    required this.dataPoints,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dp = _findLatestValid();
    if (dp == null) return const SizedBox.shrink();

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shortInterest,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Short Ratio 카드
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: l10n.shortInterestRatio,
                  value: dp.shortRatio != null
                      ? l10n.shortDays(dp.shortRatio!.toStringAsFixed(1))
                      : 'N/A',
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Short % Float 카드
              Expanded(
                child: _buildMetricCard(
                  context,
                  title: l10n.shortPercentFloat,
                  value: dp.shortPercentFloat != null
                      ? '${dp.shortPercentFloat!.toStringAsFixed(1)}%'
                      : 'N/A',
                ),
              ),
            ],
          ),
          // 하단 상태 표시
          if (dp.shortPercentFloat != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildStatusIndicator(context, dp.shortPercentFloat!),
          ],
        ],
      ),
    );
  }

  ChartDataPoint? _findLatestValid() {
    for (int i = dataPoints.length - 1; i >= 0; i--) {
      final dp = dataPoints[i];
      if (dp.shortRatio != null || dp.shortPercentFloat != null) {
        return dp;
      }
    }
    return null;
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: context.mlColors.textSecondary,
              fontWeight: AppTypography.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 비방향성 집계 히어로 숫자 → accentBlue. FittedBox로 오버플로 방어.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppTypography.displaySmall,
                fontWeight: AppTypography.bold,
                color: context.mlColors.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, double shortPctFloat) {
    final l10n = AppLocalizations.of(context);
    final Color color;
    final String text;

    final mlc = context.mlColors;
    if (shortPctFloat < 5) {
      color = mlc.gainColor;
      text = l10n.shortInterestLow;
    } else if (shortPctFloat < 20) {
      color = context.mlColors.warningColor;
      text = l10n.shortInterestModerate;
    } else {
      color = mlc.lossColor;
      text = l10n.shortInterestHigh;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: AppSpacing.md),
        Text(
          text,
          style: TextStyle(
            fontSize: AppTypography.bodyMedium,
            color: color,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ],
    );
  }
}
