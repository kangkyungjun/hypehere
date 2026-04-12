import 'package:flutter/material.dart';
import '../../../models/chart_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/multilingual.dart';
import '../../../utils/score_mapper.dart';

class TickerInsightSection extends StatefulWidget {
  final CompleteChartData chartData;
  final GlobalKey aiInsightKey;

  const TickerInsightSection({
    super.key,
    required this.chartData,
    required this.aiInsightKey,
  });

  @override
  State<TickerInsightSection> createState() => _TickerInsightSectionState();
}

class _TickerInsightSectionState extends State<TickerInsightSection> {
  bool _showAIReasons = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    // 최신 AI 분석 데이터 찾기 (null이 아닌 마지막 데이터)
    if (widget.chartData.data.isEmpty) return const SizedBox.shrink();
    final latestData = widget.chartData.data.lastWhere(
      (d) => d.aiSummary != null,
      orElse: () => widget.chartData.data.last,
    );

    // AI 데이터가 없으면 fallback 표시
    if (latestData.aiSummary == null) {
      return Container(
        key: widget.aiInsightKey,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.mlColors.subtleBorder, width: 1),
            bottom: BorderSide(color: context.mlColors.subtleBorder, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: context.mlColors.warningColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.marketlensAIOpinion,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTargetStopLossRow(),
            const SizedBox(height: AppSpacing.md),
            Text(
              _generateInsightText(latestData),
              style: TextStyle(fontSize: AppTypography.bodyLarge),
            ),
          ],
        ),
      );
    }

    // AI 상승 확률 계산
    final probability = latestData.aiProbability ?? 0.5;
    final isUptrend = probability >= 0.5;
    final confidencePercent = (probability * 100).toStringAsFixed(0);

    return Container(
      key: widget.aiInsightKey,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.mlColors.subtleBorder, width: 1),
          bottom: BorderSide(color: context.mlColors.subtleBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: context.mlColors.warningColor),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.marketlensAIOpinion,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isUptrend ? context.mlColors.gainBg : context.mlColors.lossBg,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUptrend ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isUptrend ? context.mlColors.gainColor : context.mlColors.lossColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$confidencePercent%',
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: FontWeight.bold,
                        color: isUptrend ? context.mlColors.gainColor : context.mlColors.lossColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 점수 + 시그널 라벨
          Builder(builder: (context) {
            final score = latestData.score;
            if (score == null) return const SizedBox.shrink();
            return Row(
              children: [
                Text(
                  l10n.scorePoints(score.toStringAsFixed(1)),
                  style: TextStyle(
                    fontSize: AppTypography.displaySmall,
                    fontWeight: FontWeight.bold,
                    color: ScoreMapper.getScoreColor(score, context.mlColors),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: ScoreMapper.getScoreColor(score, context.mlColors),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    ScoreMapper.getScoreLabelLocalized(score, l10n),
                    style: TextStyle(
                      color: context.mlColors.onPrimary,
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.sm),

          // 목표가 / 손절가
          _buildTargetStopLossRow(),
          const SizedBox(height: AppSpacing.sm),

          // AI Summary
          Text(
            latestData.aiSummary!.localize(langCode),
            style: const TextStyle(
              fontSize: AppTypography.headlineSmall,
              fontWeight: AppTypography.semiBold,
              height: 1.4,
            ),
          ),

          // 강세/약세 요인 접기/펼치기
          if ((latestData.aiBullishReasons != null && latestData.aiBullishReasons!.isNotEmpty) ||
              (latestData.aiBearishReasons != null && latestData.aiBearishReasons!.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () => setState(() => _showAIReasons = !_showAIReasons),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAIReasons ? l10n.hideBullBearFactors : l10n.showBullBearFactors,
                    style: TextStyle(
                      fontSize: AppTypography.bodySmall,
                      color: context.mlColors.accentBlue,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  Icon(
                    _showAIReasons ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: context.mlColors.accentBlue,
                  ),
                ],
              ),
            ),

            if (_showAIReasons) ...[
              const SizedBox(height: AppSpacing.md),

              // Bullish Reasons (강세 요인)
              if (latestData.aiBullishReasons != null && latestData.aiBullishReasons!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.bullishFactors,
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        fontWeight: AppTypography.semiBold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...latestData.aiBullishReasons!.map((reason) => Padding(
                      padding: const EdgeInsets.only(left: 22, bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: context.mlColors.gainColor)),
                          Expanded(
                            child: Text(
                              reason.localize(langCode),
                              style: const TextStyle(fontSize: AppTypography.bodyMedium, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: AppSpacing.md),
              ],

              // Bearish Reasons (약세 요인)
              if (latestData.aiBearishReasons != null && latestData.aiBearishReasons!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.thumb_down_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.bearishFactors,
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        fontWeight: AppTypography.semiBold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...latestData.aiBearishReasons!.map((reason) => Padding(
                      padding: const EdgeInsets.only(left: 22, bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: context.mlColors.lossColor)),
                          Expanded(
                            child: Text(
                              reason.localize(langCode),
                              style: const TextStyle(fontSize: AppTypography.bodyMedium, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ],
      ),
    );
  }

  /// 목표가/손절가 Row (AI 섹션 내부용)
  Widget _buildTargetStopLossRow() {
    final l10n = AppLocalizations.of(context);
    if (widget.chartData.data.isEmpty) return const SizedBox.shrink();
    final latestData = widget.chartData.data.last;
    final hasTarget = latestData.targetPrice != null;
    final hasStopLoss = latestData.stopLoss != null;

    if (!hasTarget && !hasStopLoss) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 목표가 (라벨 회색, 가격 초록)
        if (hasTarget) ...[
          Text(l10n.target,
              style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(
            '\$${latestData.targetPrice!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: AppTypography.semiBold,
              color: context.mlColors.gainColor,
            ),
          ),
        ],
        if (hasTarget && hasStopLoss) ...[
          const SizedBox(width: AppSpacing.lg),
          Container(height: 14, width: 1, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: AppSpacing.lg),
        ],
        // 손절가 (라벨 회색, 가격 빨간색)
        if (hasStopLoss) ...[
          Text(l10n.stopLoss,
              style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(
            '\$${latestData.stopLoss!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: AppTypography.semiBold,
              color: context.mlColors.lossColor,
            ),
          ),
        ],
      ],
    );
  }

  /// 인사이트 텍스트 생성
  String _generateInsightText(ChartDataPoint data) {
    final score = data.score ?? 0;
    final signal = data.signal ?? 'NEUTRAL';

    if (signal == 'BUY' && score >= 70) {
      return 'Strong buy signal detected. AI score indicates positive momentum with favorable technical indicators.';
    } else if (signal == 'BUY') {
      return 'Moderate buy signal. Consider monitoring price action and volume for confirmation.';
    } else if (signal == 'SELL' && score <= 30) {
      return 'Strong sell signal detected. AI score indicates negative momentum with concerning technical indicators.';
    } else if (signal == 'SELL') {
      return 'Moderate sell signal. Risk management recommended.';
    } else {
      return 'Neutral signal. Market conditions suggest waiting for clearer direction.';
    }
  }
}
