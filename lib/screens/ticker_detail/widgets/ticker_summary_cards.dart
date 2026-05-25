import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chart_data.dart';
import '../../../models/ticker_info.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/score_mapper.dart';
import '../../../widgets/common/bento_card.dart';
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
      child: BentoCard(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.expertCount(consensus?.count?.toString() ?? '-'),
                        style: AppTypography.label.copyWith(
                          color: context.mlColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (consensus?.recommendation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: getRecommendationColor(
                              context,
                              consensus!.recommendation,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppRadius.badge,
                            ),
                          ),
                          child: Text(
                            translateRecommendation(
                              consensus.recommendation,
                              l10n,
                            ),
                            style: TextStyle(
                              color: context.mlColors.onPrimary,
                              fontSize: AppTypography.bodyMedium,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          '--',
                          style: TextStyle(
                            fontSize: AppTypography.bodyLarge,
                            color: context.mlColors.textTertiary,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        consensus?.mean != null
                            ? '${l10n.target}\$${consensus!.mean!.toStringAsFixed(2)}'
                            : '${l10n.target}--',
                        style: AppTypography.priceCard.copyWith(
                          color: context.mlColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, color: context.mlColors.subtleBorder),
              Expanded(
                child: InkWell(
                  onTap: onScrollToAIInsight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.marketlensAI,
                                style: AppTypography.label.copyWith(
                                  color: context.mlColors.textTertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (score != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                l10n.scorePoints(score.toInt().toString()),
                                style: AppTypography.priceCard.copyWith(
                                  fontWeight: AppTypography.bold,
                                  color: ScoreMapper.getScoreColor(
                                    score,
                                    context.mlColors,
                                  ),
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
                            fontWeight: AppTypography.bold,
                            color: score != null
                                ? ScoreMapper.getScoreColor(
                                    score,
                                    context.mlColors,
                                  )
                                : context.mlColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                latestData.targetPrice != null
                                    ? '${l10n.target}\$${latestData.targetPrice!.toStringAsFixed(2)}'
                                    : '${l10n.target}--',
                                style: AppTypography.priceCard.copyWith(
                                  color: context.mlColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: context.mlColors.textTertiary,
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
      ),
    );
  }
}
