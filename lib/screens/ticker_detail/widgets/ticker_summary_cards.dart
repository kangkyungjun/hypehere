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
                          fontSize: AppTypography.bodyMedium,
                          fontWeight: AppTypography.semiBold,
                          color: context.mlColors.textSecondary,
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: '${l10n.target} ',
                              style: AppTypography.unitSuffix.copyWith(
                                color: context.mlColors.textSecondary,
                              ),
                            ),
                            if (consensus?.mean != null)
                              TextSpan(
                                text:
                                    '\$${consensus!.mean!.toStringAsFixed(2)}',
                                style: AppTypography.priceLarge.copyWith(
                                  color: context.mlColors.accentBlue,
                                ),
                              )
                            else
                              TextSpan(
                                text: '--',
                                style: AppTypography.priceLarge.copyWith(
                                  color: context.mlColors.textTertiary,
                                ),
                              ),
                          ]),
                          maxLines: 1,
                          softWrap: false,
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
                                  fontSize: AppTypography.bodyMedium,
                                  fontWeight: AppTypography.semiBold,
                                  color: context.mlColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (score != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              // FittedBox(scaleDown): 점수 숫자가 '…'로 잘려
                              // 자릿수가 숨는 것을 방지(축소로 대응).
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  // 점수 16→20 bold: 카드 헤드라인 숫자로 강조.
                                  l10n.scorePoints(score.toInt().toString()),
                                  style: AppTypography.priceLarge.copyWith(
                                    fontWeight: AppTypography.bold,
                                    color: ScoreMapper.getScoreColor(
                                      score,
                                      context.mlColors,
                                    ),
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
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
                              // FittedBox(scaleDown): 좁은 반쪽 열에서 가격이
                              // '…'로 잘리지 않게 축소(가격 숫자 은닉 방지).
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text.rich(
                                  // "목표" 라벨은 작게 뮤트, 숫자는 크게+블루
                                  // — 레퍼런스의 "큰 파란 히어로 숫자" 시그니처.
                                  TextSpan(children: [
                                    TextSpan(
                                      text: '${l10n.target} ',
                                      style: AppTypography.unitSuffix.copyWith(
                                        color: context.mlColors.textSecondary,
                                      ),
                                    ),
                                    if (latestData.targetPrice != null)
                                      TextSpan(
                                        text:
                                            '\$${latestData.targetPrice!.toStringAsFixed(2)}',
                                        style: AppTypography.priceLarge.copyWith(
                                          color: context.mlColors.accentBlue,
                                        ),
                                      )
                                    else
                                      TextSpan(
                                        text: '--',
                                        style: AppTypography.priceLarge.copyWith(
                                          color: context.mlColors.textTertiary,
                                        ),
                                      ),
                                  ]),
                                  maxLines: 1,
                                  softWrap: false,
                                ),
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
