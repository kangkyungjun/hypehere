import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticker_score.dart';
import '../../../models/treemap_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../providers/watchlist_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/dashboard/watchlist_discovery_card.dart';
import 'login_required_banner.dart';

/// Watchlist tab: shows watchlist items with [+💼] button or "보유중" badge.
class WatchlistTab extends StatelessWidget {
  final Map<String, TickerScore> tickerScores;
  final bool isLoading;
  final String? error;
  final TreemapData? treemapData;
  final void Function(String) onTickerTap;
  final void Function(String, TickerScore?) onAddHolding;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  const WatchlistTab({
    super.key,
    required this.tickerScores,
    required this.isLoading,
    this.error,
    this.treemapData,
    required this.onTickerTap,
    required this.onAddHolding,
    required this.onRefresh,
    required this.onRetry,
  });

  List<TreemapItem> _buildTopVolumeItems() {
    if (treemapData == null) return [];
    final items = treemapData!.sectors
        .expand((s) => s.items)
        .where((i) => i.tradingValue != null && i.tradingValue! > 0)
        .toList()
      ..sort((a, b) => (b.tradingValue ?? 0).compareTo(a.tradingValue ?? 0));
    return items.take(10).toList();
  }

  Color _getSignalColor(SignalType signalType) {
    switch (signalType) {
      case SignalType.buy:
        return Colors.green;
      case SignalType.sell:
        return Colors.red;
      case SignalType.hold:
      case SignalType.neutral:
        return Colors.grey;
    }
  }

  void _onRemoveTicker(
      BuildContext context, String ticker, WatchlistProvider provider) {
    final l10n = AppLocalizations.of(context);
    provider.removeFromWatchlist(ticker);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.tickerRemovedFromWatchlist(ticker)),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => provider.addToWatchlist(ticker),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final isLoggedIn = auth.isLoggedIn;

    return Consumer<WatchlistProvider>(
      builder: (context, watchlistProvider, child) {
        final allWatchlist = watchlistProvider.watchlist;

        // Empty state
        if (allWatchlist.isEmpty) {
          return _buildEmptyState(context, l10n, auth);
        }

        // Loading
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error
        if (error != null) {
          return _buildErrorState(context, l10n);
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: allWatchlist.length + (isLoggedIn ? 0 : 1),
            itemBuilder: (context, index) {
              // Login banner as first item when not logged in
              if (!isLoggedIn && index == 0) {
                return const LoginRequiredBanner();
              }
              final i = isLoggedIn ? index : index - 1;
              final ticker = allWatchlist[i];
              final tickerScore = tickerScores[ticker];
              final isHeld =
                  isLoggedIn && portfolio.isInHoldings(ticker);
              return _buildTickerItem(
                context,
                ticker,
                tickerScore,
                watchlistProvider,
                isLoggedIn,
                isHeld,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTickerItem(
    BuildContext context,
    String ticker,
    TickerScore? tickerScore,
    WatchlistProvider provider,
    bool isLoggedIn,
    bool isHeld,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasScore = tickerScore != null;

    return Dismissible(
      key: Key(ticker),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _onRemoveTicker(context, ticker, provider),
      child: Column(
        children: [
          InkWell(
            onTap: () => onTickerTap(ticker),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Score box
                  if (hasScore)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getSignalColor(tickerScore.signalType)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tickerScore.score.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getSignalColor(tickerScore.signalType),
                            ),
                          ),
                          Text(
                            l10n.score,
                            style: TextStyle(
                              fontSize: 8,
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.mlColors.sectionBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bookmark,
                        color: theme.colorScheme.outline,
                        size: 22,
                      ),
                    ),

                  const SizedBox(width: 10),

                  // Ticker + Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticker,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 1),
                        hasScore && tickerScore.name != null
                            ? Text(
                                Localizations.localeOf(context)
                                                .languageCode ==
                                            'ko' &&
                                        tickerScore.nameKo != null
                                    ? tickerScore.nameKo!
                                    : tickerScore.name!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme
                                      .colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                l10n.tapToViewDetails,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.outline,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ],
                    ),
                  ),

                  // Price + Change%
                  if (hasScore && tickerScore.close != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${tickerScore.close!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (tickerScore.changePct != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${tickerScore.changePct! >= 0 ? '+' : ''}${tickerScore.changePct!.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: tickerScore.changePct! >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(width: 6),

                  // Signal pill
                  if (hasScore && tickerScore.signal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _getSignalColor(tickerScore.signalType),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tickerScore.signalLabelLocalized(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(width: 4),

                  // [+💼] or "보유중" badge
                  if (isLoggedIn)
                    isHeld
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.alreadyHeld,
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: Icon(
                                Icons.add_business,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: l10n.addToHoldings,
                              onPressed: () =>
                                  onAddHolding(ticker, tickerScore),
                            ),
                          )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.outline,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations l10n, AuthProvider auth) {
    final topVolumeItems = _buildTopVolumeItems();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              if (!auth.isLoggedIn) ...[
                const LoginRequiredBanner(),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 32),
              Icon(
                Icons.bookmark_border,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.watchlistEmpty,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.watchlistEmptyHint,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    l10n.explore,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (topVolumeItems.isNotEmpty) ...[
                const SizedBox(height: 32),
                WatchlistDiscoveryCard(
                  topItems: topVolumeItems,
                  onTickerTap: onTickerTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            l10n.tickerDataLoadFailed,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
