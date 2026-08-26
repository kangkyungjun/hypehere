import 'package:flutter/material.dart';
import '../../models/ticker_score.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics_api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/common/ml_divider.dart';
import '../ticker_detail/ticker_detail_screen.dart';

/// Full list screen for top stocks by AI score.
///
/// Fetches top tickers from the API and displays them in a ranked list.
/// A [BannerAdWidget] is inserted every 10 data items.
class TopStocksListScreen extends StatefulWidget {
  const TopStocksListScreen({super.key});

  @override
  State<TopStocksListScreen> createState() => _TopStocksListScreenState();
}

class _TopStocksListScreenState extends State<TopStocksListScreen> {
  final _apiClient = AnalyticsApiClient();
  List<TickerScore> _stocks = [];
  bool _isLoading = true;
  int _displayCount = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stocks = await _apiClient.getTopByMarketCap(limit: 50);
      if (mounted) {
        setState(() {
          _stocks = stocks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[TopStocksList] Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final mlc = context.mlColors;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.topByMarketCap)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final visibleCount = _displayCount.clamp(0, _stocks.length);
    final adsCount = visibleCount ~/ 10;
    final hasMore = visibleCount < _stocks.length;
    final totalCount = visibleCount + adsCount + (hasMore ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.topByMarketCap)),
      body: _stocks.isEmpty
          ? Center(
              child: Text(
                l10n.noData,
                style: TextStyle(color: mlc.textTertiary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              itemCount: totalCount,
              itemBuilder: (context, index) {
                // Last item = Load More button
                if (hasMore && index == totalCount - 1) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _displayCount += 30;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            side: BorderSide(color: mlc.subtleBorder),
                          ),
                        ),
                        child: Text(
                          l10n.viewMore,
                          style: TextStyle(
                            fontSize: AppTypography.bodySmall,
                            fontWeight: AppTypography.semiBold,
                            color: mlc.accentBlue,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Ad position: after every 10 data items
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

                final stock = _stocks[dataIndex];
                final rank = dataIndex + 1;
                return _buildItemRow(
                  rank: rank,
                  stock: stock,
                  isLast: dataIndex == visibleCount - 1,
                );
              },
            ),
    );
  }

  Widget _buildItemRow({
    required int rank,
    required TickerScore stock,
    required bool isLast,
  }) {
    final mlc = context.mlColors;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final displayName = (isKo && stock.nameKo != null)
        ? stock.nameKo!
        : (stock.name ?? stock.ticker);
    final pct = stock.changePct ?? 0;
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
        stock.close != null ? '\$${_formatClose(stock.close!)}' : '-';

    return GestureDetector(
      onTap: () => _onTickerTap(stock.ticker),
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
                        stock.ticker,
                        style: TextStyle(
                          fontSize: AppTypography.headlineLarge,
                          fontWeight: AppTypography.bold,
                          color: mlc.textPrimary,
                        ),
                      ),
                      Text(
                        displayName,
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

  String _formatClose(double price) {
    if (price >= 1000) {
      final intPart = price.truncate();
      final str = intPart.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
        buffer.write(str[i]);
      }
      final decimal = ((price - intPart) * 100).round();
      if (decimal == 0) return buffer.toString();
      return '$buffer.${decimal.toString().padLeft(2, '0')}';
    }
    return price.toStringAsFixed(2);
  }
}
