import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/treemap_data.dart';
import '../../providers/watchlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Dashboard card suggesting top-volume tickers for watchlist discovery.
///
/// Shows top 10 tickers by trading volume from treemap data.
/// Each tile has a star toggle for instant watchlist add/remove.
class WatchlistDiscoveryCard extends StatelessWidget {
  final List<TreemapItem> topItems;
  final void Function(String ticker)? onTickerTap;

  const WatchlistDiscoveryCard({
    super.key,
    required this.topItems,
    this.onTickerTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (topItems.isEmpty) return const SizedBox.shrink();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.lg, 0),
            child: Row(
              children: [
                Icon(Icons.bookmark_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.watchlistDiscoveryTitle,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, 0),
            child: Text(
              l10n.watchlistDiscoverySubtitle,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
            child: Text(
              l10n.topTradingVolume,
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: AppTypography.semiBold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Ticker tiles grid
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            child: Consumer<WatchlistProvider>(
              builder: (context, watchlistProvider, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topItems.map((item) {
                    return _TickerTile(
                      item: item,
                      isInWatchlist: watchlistProvider.isInWatchlist(item.ticker),
                      onToggle: () => _onToggleWatchlist(context, watchlistProvider, item.ticker),
                      onTap: () => onTickerTap?.call(item.ticker),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
    );
  }

  void _onToggleWatchlist(
    BuildContext context,
    WatchlistProvider provider,
    String ticker,
  ) {
    final l10n = AppLocalizations.of(context);
    final wasInWatchlist = provider.isInWatchlist(ticker);
    provider.toggleWatchlist(ticker);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasInWatchlist
              ? '$ticker ${l10n.removedFromWatchlist}'
              : '$ticker ${l10n.addedToWatchlist}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Individual ticker tile with star toggle
class _TickerTile extends StatelessWidget {
  final TreemapItem item;
  final bool isInWatchlist;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TickerTile({
    required this.item,
    required this.isInWatchlist,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final changePct = item.changePct ?? 0;
    final isPositive = changePct >= 0;
    final mlc = context.mlColors;
    final changeColor = isPositive
        ? mlc.gainColor
        : mlc.lossColor;
    final arrow = isPositive ? '▲' : '▼';
    final sign = isPositive ? '+' : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.mlColors.sectionBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.mlColors.subtleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticker + star
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.ticker,
                    style: const TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                      color: isInWatchlist ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),

            // Korean name
            Text(
              item.name ?? item.ticker,
              style: TextStyle(
                fontSize: AppTypography.micro,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Change %
            Text(
              '$arrow $sign${changePct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                fontWeight: AppTypography.semiBold,
                color: changeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
