import 'package:flutter/material.dart';
import '../../../models/treemap_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/ads/banner_ad_widget.dart';
import '../../../widgets/common/bento_card.dart';
import '../../../widgets/common/ml_divider.dart';

/// Up & Down tab widget for the Dashboard.
///
/// Displays three ranked sections:
/// 1. Trading Volume Top (by tradingValue DESC)
/// 2. Gainers Top (by changePct DESC)
/// 3. Losers Top (by changePct ASC)
///
/// Each section shows the top 3 items with a "View More" button.
/// Index filter chips (All / S&P / NASDAQ / DOW) allow the parent
/// to reload treemap data for the selected index.
class UpDownTab extends StatelessWidget {
  const UpDownTab({
    super.key,
    required this.treemapData,
    required this.selectedIndex,
    required this.onIndexFilterChanged,
    required this.onTickerTap,
    required this.onViewMore,
    this.isLoading = false,
  });

  /// Treemap data from which items are extracted and sorted.
  final TreemapData? treemapData;

  /// Currently selected index filter (null = All).
  final String? selectedIndex;

  /// Called when the user taps a filter chip.
  final void Function(String?) onIndexFilterChanged;

  /// Called when the user taps a ticker row.
  final void Function(String ticker) onTickerTap;

  /// Called when the user taps "View More".
  /// [sortBy] is one of: 'trading_volume', 'gainers', 'losers'.
  final void Function(String sortBy) onViewMore;

  /// Whether the parent is loading new treemap data.
  final bool isLoading;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Flatten all TreemapItems from every sector.
  List<TreemapItem> _allItems() {
    if (treemapData == null) return [];
    return treemapData!.sectors.expand((s) => s.items).toList();
  }

  /// Top 3 by trading value (descending).
  List<TreemapItem> _tradingVolumeTop() {
    final items = _allItems()
      ..sort((a, b) => (b.tradingValue ?? 0).compareTo(a.tradingValue ?? 0));
    return items.take(5).toList();
  }

  /// Top 3 gainers (highest changePct).
  List<TreemapItem> _gainersTop() {
    final items = _allItems()
      ..sort((a, b) => (b.changePct ?? 0).compareTo(a.changePct ?? 0));
    return items.take(5).toList();
  }

  /// Top 3 losers (lowest changePct).
  List<TreemapItem> _losersTop() {
    final items = _allItems()
      ..sort((a, b) => (a.changePct ?? 0).compareTo(b.changePct ?? 0));
    return items.take(5).toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index filter chips
          _buildFilterChips(context, l10n),
          const SizedBox(height: AppSpacing.xl),

          // Content
          if (isLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (treemapData == null)
            const SizedBox.shrink()
          else ...[
            // Trading Volume Top
            _buildSection(
              context: context,
              title: l10n.tradingVolumeTop,
              items: _tradingVolumeTop(),
              sortBy: 'trading_volume',
              l10n: l10n,
            ),
            const SizedBox(height: AppSpacing.lg),
            const BannerAdWidget(),
            const SizedBox(height: AppSpacing.lg),

            // Gainers Top
            _buildSection(
              context: context,
              title: l10n.gainersTop,
              items: _gainersTop(),
              sortBy: 'gainers',
              l10n: l10n,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Losers Top
            _buildSection(
              context: context,
              title: l10n.losersTop,
              items: _losersTop(),
              sortBy: 'losers',
              l10n: l10n,
            ),
            const SizedBox(height: AppSpacing.lg),
            const BannerAdWidget(),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter chips
  // ---------------------------------------------------------------------------

  Widget _buildFilterChips(BuildContext context, AppLocalizations l10n) {
    final filters = [
      (null, l10n.filterAll),
      ('SP500', 'S&P'),
      ('NASDAQ100', l10n.filterNasdaq),
      ('DOW30', l10n.filterDow),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final code = f.$1;
          final label = f.$2;
          final isSelected = selectedIndex == code;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => onIndexFilterChanged(code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : context.mlColors.sectionBackground,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : context.mlColors.subtleBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight:
                        isSelected ? AppTypography.bold : AppTypography.regular,
                    color: isSelected
                        ? context.mlColors.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section (title + 3 items + View More)
  // ---------------------------------------------------------------------------

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<TreemapItem> items,
    required String sortBy,
    required AppLocalizations l10n,
  }) {
    final mlc = context.mlColors;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with "더보기" on the right
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTypography.headlineMedium,
                  fontWeight: AppTypography.bold,
                  color: context.mlColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onViewMore(sortBy),
                child: Text(
                  '${l10n.viewMore} >',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    fontWeight: AppTypography.semiBold,
                    color: mlc.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Items
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: mlc.textTertiary,
                  ),
                ),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              return _buildItemRow(
                context: context,
                rank: rank,
                item: item,
                isLast: rank == items.length,
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single item row
  // ---------------------------------------------------------------------------

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
      onTap: () => onTickerTap(item.ticker),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 20,
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

                // Ticker symbol + name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.ticker,
                        style: TextStyle(
                          fontSize: AppTypography.bodyLarge,
                          fontWeight: AppTypography.bold,
                          color: mlc.textPrimary,
                        ),
                      ),
                      if (item.displayName(Localizations.localeOf(context).languageCode) != null)
                        Text(
                          item.displayName(Localizations.localeOf(context).languageCode)!,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            color: mlc.textTertiary,
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

                // Change % with arrow
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
