import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../screens/ticker_detail/ticker_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/app_page_route.dart';
import '../../utils/multilingual.dart';

/// Shared modal for MARKET ticker news items.
///
/// Shows full AI summary, English title, source, and a button
/// to open the original article URL in an external browser.
class MarketNewsModal {
  MarketNewsModal._();

  /// Returns true if the news item is a non-stock news (MARKET, GEO, etc.).
  static bool isMarketNews(NewsItem item) =>
      item.ticker == 'MARKET' || item.ticker == 'GEO';

  /// Show the market news detail modal bottom sheet.
  static void show(BuildContext context, NewsItem item) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final dotColor = item.sentimentColor(context.mlColors);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.mlColors.textTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.xxs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Sentiment badge + time + source
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      isMarketNews(item) ? l10n.marketNews : item.ticker,
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.bold,
                        color: ctx.mlColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      item.sentimentLabelLocalized(l10n),
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        fontWeight: AppTypography.bold,
                        color: dotColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.timeAgoLocalized(l10n),
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: Theme.of(ctx).colorScheme.outline,
                    ),
                  ),
                ],
              ),

              if (item.source != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.source!,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: Theme.of(ctx).colorScheme.outline,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Article title section (replaces the old "AI Summary" label)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    margin: const EdgeInsets.only(top: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xxs),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.title.localize(langCode),
                      style: TextStyle(
                        fontSize: AppTypography.headlineLarge,
                        fontWeight: AppTypography.bold,
                        color: Theme.of(ctx).colorScheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // AI summary body (enlarged for readability)
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    item.aiSummary.localize(langCode),
                    style: TextStyle(
                      fontSize: AppTypography.headlineMedium,
                      fontWeight: AppTypography.medium,
                      color: Theme.of(ctx).colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              // Action buttons (horizontal, evenly split)
              ..._buildActions(ctx, context, item, l10n),

              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom action buttons: 원문 기사 보기 + 종목으로 이동, laid out
  /// horizontally and split evenly. Falls back to a single full-width
  /// button when only one applies. [sheetCtx] pops the sheet; [navCtx]
  /// is used to push the ticker screen after popping.
  static List<Widget> _buildActions(
    BuildContext sheetCtx,
    BuildContext navCtx,
    NewsItem item,
    AppLocalizations l10n,
  ) {
    final hasUrl = item.sourceUrl != null;
    final hasTicker = !isMarketNews(item) && item.ticker.isNotEmpty;
    if (!hasUrl && !hasTicker) return const [];

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );
    const pad = EdgeInsets.symmetric(vertical: AppSpacing.lg);

    final originalBtn = OutlinedButton.icon(
      onPressed: () => _launchUrl(item.sourceUrl!),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(l10n.viewOriginalArticle, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(padding: pad, shape: shape),
    );

    final tickerBtn = FilledButton.icon(
      onPressed: () {
        Navigator.pop(sheetCtx);
        Navigator.push(
          navCtx,
          appPageRoute(builder: (_) => TickerDetailScreen(ticker: item.ticker)),
        );
      },
      icon: const Icon(Icons.show_chart, size: 16),
      label: Text(l10n.viewTickerDetail, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(padding: pad, shape: shape),
    );

    return [
      const SizedBox(height: AppSpacing.xxl),
      if (hasUrl && hasTicker)
        Row(
          children: [
            Expanded(child: originalBtn),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: tickerBtn),
          ],
        )
      else
        SizedBox(
          width: double.infinity,
          child: hasUrl ? originalBtn : tickerBtn,
        ),
    ];
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
