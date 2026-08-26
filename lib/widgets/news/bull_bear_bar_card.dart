import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../common/bento_card.dart';

/// Compact card showing bullish vs bearish news counts over the last 24h
/// as two proportional horizontal bars.
///
/// ┌────────────────────────────────┐
/// │ 최근 24시간                     │
/// │ 강세뉴스 ▇▇▇▇▇▇▇▇▇▇  100건      │
/// │ 중립뉴스 ▇▇▇▇▇▇▇        70건      │
/// │ 약세뉴스 ▇▇▇▇▇▇        60건      │
/// └────────────────────────────────┘
class BullBearBarCard extends StatelessWidget {
  final SentimentCounts counts;

  const BullBearBarCard({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    if (counts.bullish + counts.neutral + counts.bearish == 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    // Shared axis across all three bars
    final maxCount = [counts.bullish, counts.neutral, counts.bearish]
        .reduce((a, b) => a > b ? a : b);

    return BentoCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      // Tighter top/bottom so 3 bars keep ~the same footprint as 2
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.newsSentiment24hTitle,
            style: TextStyle(
              fontSize: AppTypography.bodyLarge,
              fontWeight: AppTypography.semiBold,
              color: mlc.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _BarRow(
            label: l10n.newsBullish,
            count: counts.bullish,
            maxCount: maxCount,
            color: mlc.gainColor,
            countText: l10n.newsCountUnit(counts.bullish),
          ),
          const SizedBox(height: AppSpacing.xs),
          _BarRow(
            label: l10n.newsNeutral,
            count: counts.neutral,
            maxCount: maxCount,
            color: mlc.neutralColor,
            countText: l10n.newsCountUnit(counts.neutral),
          ),
          const SizedBox(height: AppSpacing.xs),
          _BarRow(
            label: l10n.newsBearish,
            count: counts.bearish,
            maxCount: maxCount,
            color: mlc.lossColor,
            countText: l10n.newsCountUnit(counts.bearish),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;
  final Color color;
  final String countText;

  const _BarRow({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.color,
    required this.countText,
  });

  @override
  Widget build(BuildContext context) {
    final mlc = context.mlColors;
    final factor = maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: AppTypography.medium,
                color: mlc.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 11,
            decoration: BoxDecoration(
              color: mlc.sectionBackground,
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: factor == 0 ? 0.01 : factor,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 48,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              countText,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                fontWeight: AppTypography.semiBold,
                color: mlc.textPrimary,
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
