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

/// Per-ticker analyst target + historical prices for the watchlist card,
/// derived client-side from getChartData (see WatchlistScreen._loadEnrichment).
class WatchlistEnrichment {
  final double? target;
  final double? price1m;
  final double? price3m;
  const WatchlistEnrichment({this.target, this.price1m, this.price3m});
}

/// Watchlist tab: 2-up grid of compact stock cards (ticker, price/change,
/// analyst target, 1M/3M-ago prices) with full-width banner ads between rows.
class WatchlistTab extends StatelessWidget {
  final Map<String, TickerScore> tickerScores;
  final Map<String, WatchlistEnrichment> enrichment;
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
    this.enrichment = const {},
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

        // Build a flat list of rows: subtitle, 2-up card rows, interleaved
        // full-width banner ads (every 2 rows), discovery card, bottom ad.
        final children = <Widget>[];

        if (!isLoggedIn) children.add(const LoginRequiredBanner());

        children.add(
          Padding(
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
          ),
        );

        final pairCount = (allWatchlist.length / 2).ceil();
        int rowsSinceAd = 0;
        for (int p = 0; p < pairCount; p++) {
          final i = p * 2;
          final t1 = allWatchlist[i];
          final t2 = (i + 1 < allWatchlist.length) ? allWatchlist[i + 1] : null;

          children.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildTickerCard(
                      context,
                      t1,
                      tickerScores[t1],
                      watchlistProvider,
                      isLoggedIn,
                      isLoggedIn && portfolio.isInHoldings(t1),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: t2 == null
                        ? const SizedBox.shrink()
                        : _buildTickerCard(
                            context,
                            t2,
                            tickerScores[t2],
                            watchlistProvider,
                            isLoggedIn,
                            isLoggedIn && portfolio.isInHoldings(t2),
                          ),
                  ),
                ],
              ),
            ),
          );
          children.add(const SizedBox(height: AppSpacing.md));

          rowsSinceAd++;
          if (rowsSinceAd >= 2 && p != pairCount - 1) {
            rowsSinceAd = 0;
            children.add(
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: BannerAdWidget(),
              ),
            );
          }
        }

        if (showDiscovery) {
          children.add(_buildDiscoverySection(context, discoveryItems));
        }

        // Bottom banner ad
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: BannerAdWidget(),
          ),
        );

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              MediaQuery.of(context).viewPadding.bottom + 64,
            ),
            children: children,
          ),
        );
      },
    );
  }

  /// Compact watchlist card (two fit per row).
  ///
  /// NOTE: swipe-to-delete (Dismissible) doesn't fit a 2-up grid cell, so
  /// removal moved to **long-press** (with undo snackbar). Tap → detail.
  /// The big score box + signal pill were dropped for the compact mockup
  /// layout; add-to-holdings is kept as a small trailing icon.
  Widget _buildTickerCard(
    BuildContext context,
    String ticker,
    TickerScore? score,
    WatchlistProvider provider,
    bool isLoggedIn,
    bool isHeld,
  ) {
    final l10n = AppLocalizations.of(context);
    final mlc = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final enrich = enrichment[ticker];

    final name = score?.name == null
        ? null
        : (isKo && score!.nameKo != null ? score.nameKo! : score!.name!);
    final priceStr = score?.close != null
        ? '\$${score!.close!.toStringAsFixed(2)}'
        : '—';

    return GestureDetector(
      onLongPress: () => _onRemoveTicker(context, ticker, provider),
      child: BentoCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () => onTickerTap(ticker),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ticker + current price
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticker,
                    style: TextStyle(
                      fontSize: AppTypography.bodyLarge,
                      fontWeight: AppTypography.bold,
                      color: mlc.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  priceStr,
                  style: AppTypography.numericSecondary.copyWith(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: AppTypography.bold,
                    color: mlc.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            // Company name + change%
            Row(
              children: [
                Expanded(
                  child: Text(
                    name ?? l10n.tapToViewDetails,
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      color: name == null ? mlc.textTertiary : mlc.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (score?.changePct != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${score!.changePct! >= 0 ? '▲' : '▼'} ${score.changePct!.abs().toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: AppTypography.caption,
                      fontWeight: AppTypography.semiBold,
                      color: score.changePct! >= 0
                          ? mlc.gainColor
                          : mlc.lossColor,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _statRow(context, l10n.wlTargetPrice, _fmtPrice(enrich?.target)),
            _statRow(context, l10n.wlPrice1mAgo, _fmtPrice(enrich?.price1m)),
            _statRow(context, l10n.wlPrice3mAgo, _fmtPrice(enrich?.price3m)),
            if (isLoggedIn) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: isHeld
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: mlc.textTertiary.withValues(alpha: 0.15),
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
                          onTap: () => onAddHolding(ticker, score),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: mlc.infoBg.withValues(alpha: 0.58),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Icon(
                              Icons.add_business,
                              size: 16,
                              color: mlc.accentBlue,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    final mlc = context.mlColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              color: mlc.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              fontWeight: AppTypography.medium,
              color: mlc.textPrimary,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double? v) =>
      v == null ? '—' : '\$${v.toStringAsFixed(2)}';

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
          // 하단은 플로팅 탭바(extendBody)에 가리지 않도록 여백 확보
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            MediaQuery.of(context).viewPadding.bottom + 64,
          ),
          child: Column(
            children: [
              if (!auth.isLoggedIn) ...[
                const LoginRequiredBanner(),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.sm),
                    _buildAddWatchlistButton(context, l10n),
                  ],
                ),
              ),
              if (topVolumeItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
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
