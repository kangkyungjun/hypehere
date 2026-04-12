import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chart_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// 기관/내부자 보유율 위젯
///
/// 서버 제공 필드: instOwnership, insiderOwnership, instChg1d/5d
/// 최신 유효 데이터 포인트에서 추출하여 카드 형태로 표시
class InstitutionalFlowWidget extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;
  final EdgeInsetsGeometry? margin;

  const InstitutionalFlowWidget({
    super.key,
    required this.dataPoints,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 역순 탐색: instOwnership 또는 foreignOwnership이 있는 마지막 데이터 포인트
    final dp = _findLatestValid();
    if (dp == null) return const SizedBox.shrink();

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.institutionalInsiderFlow,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Institutional 카드
              Expanded(
                child: _buildOwnershipCard(
                  context,
                  title: l10n.institutional,
                  ownership: dp.instOwnership,
                  chg1d: dp.instChg1d,
                  chg5d: dp.instChg5d,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Insider 카드
              Expanded(
                child: _buildOwnershipCard(
                  context,
                  title: l10n.insider,
                  ownership: dp.insiderOwnership,
                  chg1d: null,
                  chg5d: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ChartDataPoint? _findLatestValid() {
    for (int i = dataPoints.length - 1; i >= 0; i--) {
      final dp = dataPoints[i];
      if (dp.instOwnership != null ||
          dp.insiderOwnership != null ||
          dp.instChg1d != null) {
        return dp;
      }
    }
    return null;
  }

  Widget _buildOwnershipCard(
    BuildContext context, {
    required String title,
    required double? ownership,
    required double? chg1d,
    required double? chg5d,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: AppTypography.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            ownership != null ? '${ownership.toStringAsFixed(1)}%' : 'N/A',
            style: const TextStyle(
              fontSize: AppTypography.displayLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (chg1d != null) ...[
            _buildChangeBadge(context, AppLocalizations.of(context).oneDay, chg1d),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (chg5d != null) _buildChangeBadge(context, AppLocalizations.of(context).fiveDay, chg5d),
        ],
      ),
    );
  }

  Widget _buildChangeBadge(BuildContext context, String label, double change) {
    final isPositive = change > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isPositive ? context.mlColors.gainBg : context.mlColors.lossBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isPositive ? context.mlColors.gainColor : context.mlColors.lossColor,
          width: 0.5,
        ),
      ),
      child: Text(
        '$label  ${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
        style: TextStyle(
          color: isPositive ? context.mlColors.gainColor : context.mlColors.lossColor,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
