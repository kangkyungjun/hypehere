import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/treemap_data.dart';
import '../../providers/watchlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../common/bento_card.dart';

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
    final mlc = context.mlColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Icon(Icons.bookmark_outline, size: 20, color: mlc.accentBlue),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.watchlistDiscoveryTitle,
                  style: AppTypography.sectionTitle.copyWith(
                    color: mlc.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Subtitle
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            0,
          ),
          child: Text(
            l10n.watchlistDiscoverySubtitle,
            style: AppTypography.kvLabel.copyWith(color: mlc.textSecondary),
          ),
        ),

        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Text(
            l10n.topTradingVolume,
            style: AppTypography.bodyStrong.copyWith(color: mlc.textSecondary),
          ),
        ),

        // Ticker tiles grid
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Consumer<WatchlistProvider>(
            builder: (context, watchlistProvider, _) {
              // 가용 폭을 3등분해 타일 폭을 계산한다.
              //
              // 개편 전에는 `width: 110` 고정이라 3개(110×3) + 간격(8×2) = 346이
              // 가용폭 358에 못 미쳐 **오른쪽에 12px이 남고 왼쪽으로 쏠렸다**.
              // 화면 폭이 바뀌면 남는 양도 제각각이라 정렬이 항상 어긋난다.
              // 폭을 계산하면 타일이 행을 꽉 채워 좌우 여백이 대칭이 되고,
              // 카드도 그만큼 커진다.
              return LayoutBuilder(
                builder: (context, constraints) {
                  const columns = 3;
                  const gap = AppSpacing.sm;
                  final tileWidth =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: topItems.map((item) {
                      return SizedBox(
                        width: tileWidth,
                        child: _TickerTile(
                          item: item,
                          isInWatchlist: watchlistProvider.isInWatchlist(
                            item.ticker,
                          ),
                          onToggle: () => _onToggleWatchlist(
                            context,
                            watchlistProvider,
                            item.ticker,
                          ),
                          onTap: () => onTickerTap?.call(item.ticker),
                        ),
                      );
                    }).toList(),
                  );
                },
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
    final changeColor = isPositive ? mlc.gainColor : mlc.lossColor;
    final arrow = isPositive ? '▲' : '▼';
    final sign = isPositive ? '+' : '';

    // 폭은 부모가 준다(행을 꽉 채우도록 계산됨). 여기서 고정하지 않는다.
    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
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
                  // 이 타일의 대표값 — 13은 탭 대상 제목으로 너무 작았다.
                  // 홈 추천 카드의 티커(16)와 같은 위계로 맞춘다.
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: AppTypography.bold,
                    color: mlc.textPrimary,
                  ),
                  maxLines: 1,
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
                    size: 20,
                    color: isInWatchlist ? mlc.accentBlue : mlc.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Korean name
          Text(
            item.name ?? item.ticker,
            style: AppTypography.kvLabel.copyWith(color: mlc.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),

          // Change %
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$arrow $sign${changePct.toStringAsFixed(1)}%',
              // 방향성 수치는 앱 전체가 changeBadge(14 w700) 규격이다.
              style: AppTypography.changeBadge.copyWith(color: changeColor),
            ),
          ),
        ],
      ),
    );
  }
}
