import 'package:flutter/material.dart';
import '../../models/treemap_data.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/common/ml_divider.dart';
import '../ticker_detail/ticker_detail_screen.dart';
import '../../widgets/common/ml_show_more.dart';

/// Full list screen for movers (trading volume / gainers / losers).
///
/// Receives already-filtered [TreemapData] from DashboardScreen.
/// Shows items sorted by [sortBy], 30 at a time with a "Load More" button.
/// A [BannerAdWidget] is inserted every 10 data items.
class MoversListScreen extends StatefulWidget {
  final TreemapData treemapData;
  final String sortBy; // 'trading_volume' | 'gainers' | 'losers'

  const MoversListScreen({
    super.key,
    required this.treemapData,
    required this.sortBy,
  });

  @override
  State<MoversListScreen> createState() => _MoversListScreenState();
}

class _MoversListScreenState extends State<MoversListScreen> {
  int _displayCount = 30;
  late List<TreemapItem> _sortedItems;

  @override
  void initState() {
    super.initState();
    _sortedItems = _buildSortedItems();
  }

  List<TreemapItem> _buildSortedItems() {
    final items = widget.treemapData.sectors
        .expand((s) => s.items)
        .toList();
    switch (widget.sortBy) {
      case 'trading_volume':
        items.sort(
            (a, b) => (b.tradingValue ?? 0).compareTo(a.tradingValue ?? 0));
        break;
      case 'gainers':
        items.sort((a, b) => (b.changePct ?? 0).compareTo(a.changePct ?? 0));
        break;
      case 'losers':
        items.sort((a, b) => (a.changePct ?? 0).compareTo(b.changePct ?? 0));
        break;
      case 'volume':
        items.sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));
        break;
    }
    return items;
  }

  String _title(AppLocalizations l10n) {
    switch (widget.sortBy) {
      case 'trading_volume':
        return l10n.tradingVolumeTop;
      case 'gainers':
        return l10n.gainersTop;
      case 'losers':
        return l10n.losersTop;
      case 'volume':
        return l10n.volumeTop;
      default:
        return '';
    }
  }

  void _onTickerTap(String ticker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TickerDetailScreen(ticker: ticker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final visibleCount =
        _displayCount.clamp(0, _sortedItems.length);
    final adsCount = visibleCount ~/ 10;
    final hasMore = visibleCount < _sortedItems.length;
    final totalCount = visibleCount + adsCount + (hasMore ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(l10n)),
      ),
      body: ListView.builder(
        // 외곽 패딩 축소 (좌우 xl→sm, 상하 lg→xs) — 등락 탭과 동일 취지
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          // Last item = Load More button
          if (hasMore && index == totalCount - 1) {
            return MlShowMoreButton(
              expanded: false,
              collapsible: false,
              remaining: _sortedItems.length - visibleCount,
              onPressed: () =>
                  setState(() => _displayCount += 30),
            );
          }

          // Ad position: after every 10 data items
          // Pattern per group of 11: indices 0-9 = data, index 10 = ad
          if ((index + 1) % 11 == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: BannerAdWidget(),
            );
          }

          // Data item
          final adsBefore = index ~/ 11;
          final dataIndex = index - adsBefore;
          if (dataIndex >= visibleCount) {
            return const SizedBox.shrink();
          }

          final item = _sortedItems[dataIndex];
          final rank = dataIndex + 1;
          return _buildItemRow(
            context: context,
            rank: rank,
            item: item,
            isLast: dataIndex == visibleCount - 1,
          );
        },
      ),
    );
  }

  Widget _buildItemRow({
    required BuildContext context,
    required int rank,
    required TreemapItem item,
    required bool isLast,
  }) {
    final mlc = context.mlColors;
    final pct = item.changePct ?? 0;
    final color = pct > 0
        ? mlc.gainColor
        : pct < 0
            ? mlc.lossColor
            : mlc.neutralColor;
    final arrow = pct > 0
        ? '\u25B2'
        : pct < 0
            ? '\u25BC'
            : '\u2500';
    final sign = pct >= 0 ? '+' : '';
    final closeStr =
        item.close != null ? '\$${item.close!.toStringAsFixed(2)}' : '-';

    return GestureDetector(
      onTap: () => _onTickerTap(item.ticker),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.semiBold,
                      color: mlc.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Ticker + name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.ticker,
                        // 회사 티커를 더 크게(가독성↑): bodyLarge → headlineLarge
                        style: TextStyle(
                          fontSize: AppTypography.headlineLarge,
                          fontWeight: AppTypography.bold,
                          color: mlc.textPrimary,
                        ),
                      ),
                      if (item.displayName(Localizations.localeOf(context).languageCode) != null)
                        Text(
                          item.displayName(Localizations.localeOf(context).languageCode)!,
                          // 라벨 가독성↑: 힌트색→보조색 승격, bodySmall→bodyMedium
                          style: TextStyle(
                            fontSize: AppTypography.bodyMedium,
                            color: mlc.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Close price
                Text(
                  closeStr,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: AppTypography.medium,
                    color: mlc.textSecondary,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Change %
                SizedBox(
                  width: 80,
                  child: Text(
                    '$arrow $sign${pct.toStringAsFixed(2)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppTypography.bodyMedium,
                      fontWeight: AppTypography.semiBold,
                      color: color,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) const MlDivider(),
        ],
      ),
    );
  }
}
