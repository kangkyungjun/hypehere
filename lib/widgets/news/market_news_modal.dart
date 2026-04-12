import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/multilingual.dart';

/// Shared modal for MARKET ticker news items.
///
/// Shows full AI summary, English title, source, and a button
/// to open the original article URL in an external browser.
class MarketNewsModal {
  MarketNewsModal._();

  /// Returns true if the news item is a market-wide news (ticker == "MARKET").
  static bool isMarketNews(NewsItem item) => item.ticker == 'MARKET';

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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      isMarketNews(item) ? l10n.marketNews : item.ticker,
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.bold,
                        color: ctx.mlColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      item.sentimentLabelLocalized(l10n),
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.bold,
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
                    fontSize: AppTypography.bodySmall,
                    color: Theme.of(ctx).colorScheme.outline,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // AI summary section
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xxs),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.aiSummary,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.semiBold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                item.aiSummary.localize(langCode),
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  fontWeight: AppTypography.semiBold,
                  color: Theme.of(ctx).colorScheme.onSurface,
                  height: 1.5,
                ),
              ),

              // Source URL button
              if (item.sourceUrl != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(item.sourceUrl!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l10n.viewOriginalArticle),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
