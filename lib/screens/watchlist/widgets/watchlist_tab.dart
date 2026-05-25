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
import '../../../widgets/ads/banner_ad_widget.dart';
import '../../../widgets/common/bento_card.dart';
import '../../../widgets/common/error_state_view.dart';
import '../../../widgets/common/coach_mark_overlay.dart';
import '../../../providers/coach_mark_provider.dart';
import '../../explore/explore_screen.dart';
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
    final items =
        treemapData!.sectors
            .expand((s) => s.items)
            .where((i) => i.tradingValue != null && i.tradingValue! > 0)
            .toList()
          ..sort(
            (a, b) => (b.tradingValue ?? 0).compareTo(a.tradingValue ?? 0),
          );
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
    BuildContext context,
    String ticker,
    WatchlistProvider provider,
  ) {
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

        // Discovery card: show when 1-4 items & undiscovered tickers exist
        final topVolumeItems = _buildTopVolumeItems();
        final discoveryItems = topVolumeItems
            .where((item) => !watchlistProvider.isInWatchlist(item.ticker))
            .toList();
        final showDiscovery =
            allWatchlist.length < 5 && discoveryItems.isNotEmpty;

        final loginBannerCount = isLoggedIn ? 0 : 1;
        const subtitleCount = 1; // watchlist subtitle
        final discoveryCount = showDiscovery ? 1 : 0;
        const adBannerCount = 1; // bottom banner ad
        final totalCount =
            loginBannerCount +
            subtitleCount +
            allWatchlist.length +
            discoveryCount +
            adBannerCount;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            itemCount: totalCount,
            itemBuilder: (context, index) {
              // Login banner as first item when not logged in
              if (!isLoggedIn && index == 0) {
                return const LoginRequiredBanner();
              }
              final adjusted = isLoggedIn ? index : index - 1;

              // Subtitle row
              if (adjusted == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxs,
                    AppSpacing.sm,
                    AppSpacing.xxs,
                    AppSpacing.md,
                  ),
                  child: Text(
                    l10n.watchlistSubtitle,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: context.mlColors.textSecondary,
                    ),
                  ),
                );
              }
              final listAdjusted = adjusted - 1;

              // Discovery card
              if (showDiscovery && listAdjusted == allWatchlist.length) {
                return _buildDiscoverySection(context, discoveryItems);
              }

              // Banner ad as last item
              final adIndex = allWatchlist.length + discoveryCount;
              if (listAdjusted == adIndex) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: BannerAdWidget(),
                );
              }

              if (listAdjusted >= allWatchlist.length) {
                return const SizedBox.shrink();
              }
              final ticker = allWatchlist[listAdjusted];
              final tickerScore = tickerScores[ticker];
              final isHeld = isLoggedIn && portfolio.isInHoldings(ticker);
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
    final mlc = context.mlColors;
    final hasScore = tickerScore != null;

    return Dismissible(
      key: Key(ticker),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: mlc.dangerColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        child: Icon(Icons.delete, color: mlc.onPrimary),
      ),
      onDismissed: (_) => _onRemoveTicker(context, ticker, provider),
      child: BentoCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        onTap: () => onTickerTap(ticker),
        child: Row(
          children: [
            // Score box
            if (hasScore)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getSignalColor(
                    context,
                    tickerScore.signalType,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tickerScore.score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: AppTypography.headlineMedium,
                        fontWeight: AppTypography.bold,
                        color: _getSignalColor(context, tickerScore.signalType),
                      ),
                    ),
                    Text(
                      l10n.score,
                      style: TextStyle(
                        fontSize: AppTypography.chartMicro,
                        color: mlc.textTertiary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: mlc.infoBg.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(Icons.bookmark, color: mlc.textTertiary, size: 22),
              ),

            const SizedBox(width: AppSpacing.lg),

            // Ticker + Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker,
                    style: TextStyle(
                      fontSize: AppTypography.headlineSmall,
                      fontWeight: AppTypography.bold,
                      color: mlc.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  hasScore && tickerScore.name != null
                      ? Text(
                          Localizations.localeOf(context).languageCode ==
                                      'ko' &&
                                  tickerScore.nameKo != null
                              ? tickerScore.nameKo!
                              : tickerScore.name!,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: mlc.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          l10n.tapToViewDetails,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: mlc.textTertiary,
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
                    style: AppTypography.numericSecondary.copyWith(
                      fontSize: AppTypography.bodyLarge,
                      color: mlc.textPrimary,
                    ),
                  ),
                  if (tickerScore.changePct != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${tickerScore.changePct! >= 0 ? '+' : ''}${tickerScore.changePct!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: AppTypography.caption,
                        fontWeight: AppTypography.semiBold,
                        color: tickerScore.changePct! >= 0
                            ? context.mlColors.gainColor
                            : context.mlColors.lossColor,
                        fontFeatures: AppTypography.tabularFigures,
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
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getSignalColor(context, tickerScore.signalType),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  tickerScore.signalLabelLocalized(l10n),
                  style: TextStyle(
                    color: context.mlColors.onPrimary,
                    fontSize: AppTypography.micro,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),

            const SizedBox(width: AppSpacing.xs),

            // [+💼] or "보유중" badge
            if (isLoggedIn)
              isHeld
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Text(
                        l10n.alreadyHeld,
                        style: TextStyle(
                          fontSize: AppTypography.micro,
                          color: mlc.textSecondary,
                        ),
                      ),
                    )
                  : Tooltip(
                      message: l10n.addToHoldings,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        onTap: () => onAddHolding(ticker, tickerScore),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: mlc.infoBg.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Icon(
                            Icons.add_business,
                            size: 20,
                            color: mlc.accentBlue,
                          ),
                        ),
                      ),
                    )
            else
              Icon(Icons.chevron_right, color: mlc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider auth,
  ) {
    final topVolumeItems = _buildTopVolumeItems();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              if (!auth.isLoggedIn) ...[
                const LoginRequiredBanner(),
                const SizedBox(height: AppSpacing.xl),
              ],
              const SizedBox(height: AppSpacing.xl),
              BentoCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    CoachMark(
                      coachKey: CoachMarkProvider.keyWatchlist,
                      message: l10n.coachMarkWatchlist,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: context.mlColors.infoBg.withValues(
                            alpha: 0.48,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Icon(
                          Icons.bookmark_border,
                          size: 34,
                          color: context.mlColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.watchlistEmpty,
                      style: TextStyle(
                        fontSize: AppTypography.headlineMedium,
                        fontWeight: AppTypography.bold,
                        color: context.mlColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.watchlistEmptyHint,
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        color: context.mlColors.textSecondary,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAddWatchlistButton(context, l10n),
                  ],
                ),
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

  Widget _buildDiscoverySection(BuildContext context, List<TreemapItem> items) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: WatchlistDiscoveryCard(
            topItems: items,
            onTickerTap: onTickerTap,
          ),
        ),
        _buildAddWatchlistButton(context, l10n),
      ],
    );
  }

  Widget _buildAddWatchlistButton(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: FilledButton.tonal(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 16),
            const SizedBox(width: AppSpacing.md),
            Text(l10n.addWatchlistSearch),
          ],
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
