import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../utils/multilingual.dart';
import '../../screens/news/news_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../news/market_news_modal.dart';

/// Dashboard news timeline card (latest 3 items)
///
/// Timeline layout with left dot + vertical line.
/// Tapping an item navigates to TickerDetailScreen.
/// "전체보기" navigates to NewsListScreen.
class NewsCard extends StatelessWidget {
  final List<NewsItem> items;
  final void Function(String ticker)? onTickerTap;

  const NewsCard({
    super.key,
    required this.items,
    this.onTickerTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.lg, 0),
            child: Row(
              children: [
                Icon(Icons.article_outlined, size: 20, color: context.mlColors.warningColor),
                const SizedBox(width: AppSpacing.md),
                Text(
                  l10n.aiSummaryNews,
                  style: TextStyle(
                    fontSize: AppTypography.headlineSmall,
                    fontWeight: AppTypography.bold,
                    color: context.mlColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewsListScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.viewAll,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: context.mlColors.warningColor,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: context.mlColors.warningColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline items
          const SizedBox(height: AppSpacing.md),
          ...List.generate(items.length, (i) {
            return _buildTimelineItem(context, items[i], isLast: i == items.length - 1);
          }),
          const SizedBox(height: AppSpacing.md),
        ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, NewsItem item, {required bool isLast}) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final dotColor = item.sentimentColor(context.mlColors);

    final isMarket = MarketNewsModal.isMarketNews(item);

    return InkWell(
      onTap: () => isMarket
          ? MarketNewsModal.show(context, item)
          : onTickerTap?.call(item.ticker),
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
                      // First row: ticker badge + sentiment label + time
                      Row(
                        children: [
                          // Ticker badge (MARKET → "시장 뉴스", otherwise ticker + Korean name)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: isMarket
                                  ? context.mlColors.groupedBackground
                                  : context.mlColors.infoBg,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              isMarket
                                  ? l10n.marketNews
                                  : (langCode == 'ko' && item.tickerNameKo != null)
                                      ? '${item.ticker} ${item.tickerNameKo}'
                                      : item.ticker,
                              style: TextStyle(
                                fontSize: AppTypography.caption,
                                fontWeight: AppTypography.bold,
                                color: isMarket
                                    ? context.mlColors.textSecondary
                                    : context.mlColors.accentBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Breaking badge
                          if (item.isBreaking) ...[
                            const Text('🚨', style: TextStyle(fontSize: AppTypography.bodySmall)),
                            const SizedBox(width: AppSpacing.xs),
                          ],

                          // Sentiment label
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              item.sentimentLabelLocalized(l10n),
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                fontWeight: AppTypography.bold,
                                color: dotColor,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Sector abbreviation (grey)
                          if (item.sectorShort != null) ...[
                            Text(
                              item.sectorShort!,
                              style: TextStyle(
                                fontSize: AppTypography.micro,
                                color: context.mlColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],

                          // Time ago
                          Text(
                            item.timeAgoLocalized(l10n),
                            style: TextStyle(
                              fontSize: AppTypography.micro,
                              color: context.mlColors.textTertiary,
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
                          color: context.mlColors.textPrimary,
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
