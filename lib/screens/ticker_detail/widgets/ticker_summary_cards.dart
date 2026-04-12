import 'package:flutter/material.dart';
import '../../../models/chart_data.dart';
import '../../../models/ticker_info.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_radius.dart';
import '../../../utils/score_mapper.dart';
import '../../../l10n/app_localizations.dart';
import 'ticker_detail_helpers.dart';

class TickerSummaryCards extends StatelessWidget {
  final CompleteChartData chartData;
  final TickerInfo? tickerInfo;
  final VoidCallback onScrollToAIInsight;

  const TickerSummaryCards({
    super.key,
    required this.chartData,
    this.tickerInfo,
    required this.onScrollToAIInsight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final consensus = chartData.analystConsensus;
    if (chartData.data.isEmpty) return const SizedBox.shrink();
    final latestData = chartData.data.last;
    final score = latestData.score;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 왼쪽: 전문가 카드
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.expertCount(consensus?.count?.toString() ?? '-'),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (consensus?.recommendation != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: getRecommendationColor(context, consensus!.recommendation),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          translateRecommendation(consensus.recommendation, l10n),
                          style: TextStyle(
                            color: context.mlColors.onPrimary,
                            fontSize: AppTypography.bodyMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text('--', style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        color: Theme.of(context).colorScheme.outline,
                      )),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      consensus?.mean != null
                          ? '${l10n.target}\$${consensus!.mean!.toStringAsFixed(2)}'
                          : '${l10n.target}--',
                      style: TextStyle(
                        fontSize: AppTypography.headlineSmall,
                        fontWeight: AppTypography.semiBold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 세로 구분선
            Container(
              width: 1,
              color: context.mlColors.subtleBorder,
            ),
            // 오른쪽: 마켓랜즈 AI 카드 (탭 가능)
            Expanded(
              child: InkWell(
                onTap: onScrollToAIInsight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.marketlensAI,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                          if (score != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.scorePoints(score.toInt().toString()),
                              style: TextStyle(
                                fontSize: AppTypography.headlineMedium,
                                fontWeight: FontWeight.bold,
                                color: ScoreMapper.getScoreColor(score, context.mlColors),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        score != null
                            ? ScoreMapper.getScoreLabelLocalized(score, l10n)
                            : '--',
                        style: TextStyle(
                          fontSize: AppTypography.headlineLarge,
                          fontWeight: AppTypography.semiBold,
                          color: score != null
                              ? ScoreMapper.getScoreColor(score, context.mlColors)
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            latestData.targetPrice != null
                                ? '${l10n.target}\$${latestData.targetPrice!.toStringAsFixed(2)}'
                                : '${l10n.target}--',
                            style: TextStyle(
                              fontSize: AppTypography.headlineSmall,
                              fontWeight: AppTypography.semiBold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
