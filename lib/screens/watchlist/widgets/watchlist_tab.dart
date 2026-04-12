import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ticker_score.dart';
import '../../../models/treemap_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../providers/watchlist_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/dashboard/watchlist_discovery_card.dart';
import '../../../widgets/common/error_state_view.dart';
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

  Color _getSignalColor(BuildContext context, SignalType signalType) {
    switch (signalType) {
      case SignalType.buy:
        return context.mlColors.gainColor;
      case SignalType.sell:
        return context.mlColors.lossColor;
      case SignalType.hold:
      case SignalType.neutral:
        return context.mlColors.neutralColor;
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
        color: context.mlColors.dangerColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        child: Icon(Icons.delete, color: context.mlColors.onPrimary),
      ),
      onDismissed: (_) => _onRemoveTicker(context, ticker, provider),
      child: Column(
        children: [
          InkWell(
            onTap: () => onTickerTap(ticker),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  // Score box
                  if (hasScore)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getSignalColor(context, tickerScore.signalType)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tickerScore.score.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: AppTypography.headlineMedium,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getSignalColor(context, tickerScore.signalType),
                            ),
                          ),
                          Text(
                            l10n.score,
                            style: TextStyle(
                              fontSize: AppTypography.chartMicro,
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
                        borderRadius: BorderRadius.circular(AppRadius.lg),
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
                            fontSize: AppTypography.headlineSmall,
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
                                  fontSize: AppTypography.bodySmall,
                                  color: theme
                                      .colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                l10n.tapToViewDetails,
                                style: TextStyle(
                                  fontSize: AppTypography.bodySmall,
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
                            fontSize: AppTypography.bodySmall,
                            color:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (tickerScore.changePct != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${tickerScore.changePct! >= 0 ? '+' : ''}${tickerScore.changePct!.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: AppTypography.caption,
                              fontWeight: AppTypography.medium,
                              color: tickerScore.changePct! >= 0
                                  ? context.mlColors.gainColor
                                  : context.mlColors.lossColor,
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(width: AppSpacing.sm),

                  // Signal pill
                  if (hasScore && tickerScore.signal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color:
                            _getSignalColor(context, tickerScore.signalType),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        tickerScore.signalLabelLocalized(l10n),
                        style: TextStyle(
                          color: context.mlColors.onPrimary,
                          fontSize: AppTypography.micro,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(width: AppSpacing.xs),

                  // [+💼] or "보유중" badge
                  if (isLoggedIn)
                    isHeld
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(
                              l10n.alreadyHeld,
                              style: TextStyle(
                                fontSize: AppTypography.micro,
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
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            children: [
              if (!auth.isLoggedIn) ...[
                const LoginRequiredBanner(),
                const SizedBox(height: AppSpacing.xl),
              ],
              const SizedBox(height: AppSpacing.xxxl),
              Icon(
                Icons.bookmark_border,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n.watchlistEmpty,
                style: const TextStyle(
                  fontSize: AppTypography.displayMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.watchlistEmptyHint,
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.explore,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
              if (topVolumeItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxxl),
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
    return ErrorStateView(
      message: l10n.tickerDataLoadFailed,
      detail: error,
      onRetry: onRetry,
      retryLabel: l10n.retry,
    );
  }
}
