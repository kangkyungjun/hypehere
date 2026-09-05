import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../utils/multilingual.dart';
import '../../screens/news/ticker_news_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../common/section_header.dart';
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
          // 섹션 헤더 — 주황 아이콘 앵커를 걷어내고 액센트 바로 통일한다.
          // 건수는 자격 태그(subtitle)로, 전체보기는 trailing으로 분리했다.
          // 감성 통계는 헤더에 눌려 있었으므로 아래 자기 줄로 내린다.
          SectionHeader(
            title: l10n.tickerNews(ticker),
            subtitle: items.isNotEmpty ? l10n.newsCount(items.length) : null,
            onTrailingTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TickerNewsListScreen(
                  ticker: ticker,
                  stats: stats,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.viewAll,
                  style: AppTypography.label.copyWith(
                    color: context.mlColors.accentBlue,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: context.mlColors.accentBlue,
                ),
              ],
            ),
          ),

          // 감성 통계 — 헤더에서 분리된 독립 행.
          if (stats != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(context, l10n.oneWeek, stats!.week),
                  const SizedBox(height: AppSpacing.xxs),
                  _buildStatsRow(context, l10n.oneMonth, stats!.month),
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
                  color: context.mlColors.textTertiary,
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
            color: context.mlColors.textTertiary,
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
