import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../utils/multilingual.dart';
import '../../screens/news/ticker_news_list_screen.dart';
import '../../theme/app_colors.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: context.mlColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.mlColors.chartGridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: icon + title + badge
                Icon(Icons.article_outlined, size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text(
                  l10n.tickerNews(ticker),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.newsCount(items.length),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),

                const SizedBox(width: 10),

                // Center: sentiment stats (2 lines)
                if (stats != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatsRow(context, l10n.oneWeek, stats!.week),
                        const SizedBox(height: 2),
                        _buildStatsRow(context, l10n.oneMonth, stats!.month),
                      ],
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: 4),

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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.viewAll,
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: Colors.orange.shade600),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline items
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(items.length, (i) {
              return _buildTimelineItem(context, items[i], isLast: i == items.length - 1);
            }),
            const SizedBox(height: 8),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.noNews,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
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
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(width: 4),
        _buildStatChip(l10n.sentimentBullish, counts.bullish, Colors.green),
        const SizedBox(width: 3),
        _buildStatChip(l10n.sentimentNeutral, counts.neutral, Colors.grey),
        const SizedBox(width: 3),
        _buildStatChip(l10n.sentimentBearish, counts.bearish, Colors.red),
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
        const SizedBox(width: 2),
        Text(
          '$label$count',
          style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, NewsItem item, {required bool isLast}) {
    final langCode = Localizations.localeOf(context).languageCode;
    final dotColor = item.sentimentColor;

    return InkWell(
      onTap: () => MarketNewsModal.show(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot + line
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
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
              const SizedBox(width: 8),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row: sentiment label + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.sentimentLabelLocalized(AppLocalizations.of(context)),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: dotColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.timeAgoLocalized(AppLocalizations.of(context)),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // AI summary (localized)
                      Text(
                        item.aiSummary.localize(langCode),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
