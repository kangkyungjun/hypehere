import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../utils/multilingual.dart';
import '../../screens/news/ticker_news_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../news/market_news_modal.dart';

/// Ticker detail news card (3 items + inline sentiment stats)
///
/// Header row: 📰 {TICKER} 뉴스 [N건] + week/month stats + 전체보기
/// Body: timeline layout (dot + vertical line)
class TickerNewsCard extends StatelessWidget {
  final String ticker;
  final List<NewsItem> items;
  final NewsSentimentStats? stats;
  final void Function(String ticker)? onTickerTap;

  const TickerNewsCard({
    super.key,
    required this.ticker,
    required this.items,
    this.stats,
    this.onTickerTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty && stats == null) return const SizedBox.shrink();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.lg, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: icon + title + badge
                Icon(Icons.article_outlined, size: 20, color: context.mlColors.warningColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.tickerNews(ticker),
                  style: TextStyle(
                    fontSize: AppTypography.headlineSmall,
                    fontWeight: AppTypography.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: context.mlColors.warningBg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      l10n.newsCount(items.length),
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: AppTypography.bold,
                        color: context.mlColors.warningColor,
                      ),
                    ),
                  ),

                const SizedBox(width: AppSpacing.lg),

                // Center: sentiment stats (2 lines)
                if (stats != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatsRow(context, l10n.oneWeek, stats!.week),
                        const SizedBox(height: AppSpacing.xxs),
                        _buildStatsRow(context, l10n.oneMonth, stats!.month),
                      ],
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: AppSpacing.xs),

                // Right: 전체보기
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TickerNewsListScreen(
                        ticker: ticker,
                        stats: stats,
                      ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.viewAll,
                        style: TextStyle(fontSize: AppTypography.caption, color: context.mlColors.warningColor),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: context.mlColors.warningColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline items
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...List.generate(items.length, (i) {
              return _buildTimelineItem(context, items[i], isLast: i == items.length - 1);
            }),
            const SizedBox(height: AppSpacing.md),
          ] else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                l10n.noNews,
                style: TextStyle(
                  fontSize: AppTypography.bodySmall,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
    );
  }

  Widget _buildStatsRow(BuildContext context, String period, SentimentCounts counts) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          period,
          style: TextStyle(
            fontSize: AppTypography.chartLabel,
            fontWeight: AppTypography.semiBold,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _buildStatChip(l10n.sentimentBullish, counts.bullish, context.mlColors.gainColor),
        const SizedBox(width: AppSpacing.xxs),
        _buildStatChip(l10n.sentimentNeutral, counts.neutral, context.mlColors.neutralColor),
        const SizedBox(width: AppSpacing.xxs),
        _buildStatChip(l10n.sentimentBearish, counts.bearish, context.mlColors.lossColor),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '$label$count',
          style: TextStyle(fontSize: AppTypography.chartLabel, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, NewsItem item, {required bool isLast}) {
    final langCode = Localizations.localeOf(context).languageCode;
    final dotColor = item.sentimentColor(context.mlColors);

    return InkWell(
      onTap: () => MarketNewsModal.show(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot + line
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: context.mlColors.chartGridLine,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row: breaking badge + sentiment label + time
                      Row(
                        children: [
                          if (item.isBreaking) ...[
                            const Text('🚨', style: TextStyle(fontSize: AppTypography.bodySmall)),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              item.sentimentLabelLocalized(AppLocalizations.of(context)),
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                fontWeight: AppTypography.bold,
                                color: dotColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.timeAgoLocalized(AppLocalizations.of(context)),
                            style: TextStyle(
                              fontSize: AppTypography.micro,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // AI summary (localized)
                      Text(
                        item.aiSummary.localize(langCode),
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          fontWeight: AppTypography.semiBold,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
